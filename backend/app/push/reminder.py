"""One reminder of a task and sending it to the people it is for, what it
tells the app (the payload the phone's own reminder carries), and whether
the server sends the reminders at all."""

from collections.abc import Callable, Iterable
from dataclasses import dataclass
from datetime import date, datetime
from uuid import UUID

from flask import current_app
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.extensions import get_push_sender
from app.models import AccountSession
from app.push.audience import Audience
from app.push.notify import Push, Target, notify
from app.push.sender import PushMessage


# Between the parts of a payload (reminder_payload_parts.dart).
_PARTS = "\x1f"

# The iOS category of a reminder that can be put off, with its button
# «ذكّرني لاحقًا»; the app registers it (reminder_channel.dart).
SNOOZE_CATEGORY = "tafaqod.reminder"


def _day(day: date) -> str:
    """A day as the app's snooze keys write it: «2026-11-5», no zeros."""
    return f"{day.year}-{day.month}-{day.day}"


def dose_payload(
    circle_id: UUID, schedule_id: str, day: date, medicine: str,
    title: str, body: str,
) -> str:
    """A dose's (`doseSnoozeKey`; its subject is the medicine's name)."""
    key = f"{circle_id}|{schedule_id}|{_day(day)}"
    return _PARTS.join((f"dose:{circle_id}", title, body, key, medicine))


def measurement_payload(
    circle_id: UUID, version_id: str, wall_time: str, day: date, kind: str,
    title: str, body: str,
) -> str:
    """A reading time's (`measurementSnoozeKey`; its subject is the app's
    name of the kind, «bp» for blood_pressure)."""
    key = f"{circle_id}|measurement|{version_id}|{wall_time}|{_day(day)}"
    subject = "bp" if kind == "blood_pressure" else kind
    head = f"measurement:{circle_id}"
    return _PARTS.join((head, title, body, key, subject))


def appointment_payload(
    circle_id: UUID, appointment_id: UUID, title: str, body: str
) -> str:
    """A visit's: its circle, then «@» and its id (`appointmentIdMark`);
    it cannot be put off, so it carries no words."""
    return f"appointment:{circle_id}@{appointment_id}"


# What one person reads, a title and a line, from their name and, for
# someone caring for the patient, the patient's name.
Words = Callable[[str | None, str | None], tuple[str, str]]


@dataclass(frozen=True)
class Reminder:
    """A reminder due at `at`.

    `claim` (app.push.audience) keeps it to once: the kind, the task, its
    day and its time. `words` gives each person their own title and line, and
    `payload` the phone's own reminder's payload for them. The app reads
    its `kind` and the item a tap opens (`target`). `to` is who it reminds,
    everyone in the circle when None; a reminder that can be put off
    (`snoozable`) shows «ذكّرني لاحقًا»."""

    at: datetime
    claim: tuple[str, str, str, str]
    kind: str
    target: Target
    words: Words
    payload: Callable[[str, str], str]
    snoozable: bool = False
    to: frozenset[UUID] | None = None


def send_reminder(
    reminder: Reminder,
    circle_id: UUID,
    audience: Audience,
    listening: set[UUID],
) -> None:
    """Send each person `reminder` is for their own words, if their phone
    leaves its reminders to the server (`listening`): the others' phones
    set their own."""
    for account_id, name in audience.names.items():
        if account_id not in listening:
            continue
        if reminder.to is not None and account_id not in reminder.to:
            continue
        own = account_id == audience.patient_account_id
        title, body = reminder.words(
            name, None if own else audience.patient_name
        )
        message = PushMessage(
            title,
            body,
            reminder.kind,
            (*reminder.target, ("reminder", reminder.payload(title, body))),
            # Stacked by circle on the phone, as its own reminders are.
            thread=str(circle_id),
            category=SNOOZE_CATEGORY if reminder.snoozable else None,
        )
        notify(Push((account_id,), message, reminder=True))


def reminders_on() -> bool:
    """Whether the server sends the reminders now: SERVER_REMINDERS is on
    and OneSignal is set up (without it, none could reach a phone)."""
    return bool(current_app.config.get("SERVER_REMINDERS")) and bool(
        get_push_sender().enabled
    )


def listening(session: Session, accounts: Iterable[UUID]) -> set[UUID]:
    """Those of `accounts` signed in on a phone whose app leaves its
    reminders to the server; read in the caller's transaction."""
    accounts = list(accounts)
    if not accounts:
        return set()
    return set(
        session.scalars(
            select(AccountSession.account_id)
            .where(
                AccountSession.account_id.in_(accounts),
                AccountSession.revoked_at.is_(None),
                AccountSession.server_reminders.is_(True),
                AccountSession.push_subscription_id.is_not(None),
            )
            .distinct()
        )
    )
