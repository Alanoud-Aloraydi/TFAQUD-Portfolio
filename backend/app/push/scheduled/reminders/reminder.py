"""One reminder of a task, and sending it to the people it is for."""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from app.push.notify import Push, notify
from app.push.scheduled.audience import Audience
from app.push.scheduled.reminders.payloads import SNOOZE_CATEGORY
from app.push.sender import PushMessage
from app.push.targets import Target

# What one person reads, a title and a line, from their name and, for
# someone caring for the patient, the patient's name.
Words = Callable[[str | None, str | None], tuple[str, str]]


@dataclass(frozen=True)
class Reminder:
    """A reminder due at `at`.

    `claim` keeps it to once: the kind, the task, its day and its time
    (claims.py). `words` gives each person their own title and line, and
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
