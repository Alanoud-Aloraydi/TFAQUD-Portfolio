"""Sending one message to the phones of some accounts, through OneSignal,
after the request's transaction has committed: a push never announces
something that was rolled back, and a push that fails never fails the
request.

Each result is counted, the sign-ins of phones whose app was deleted end,
and each push says which item it is about (a dose, a reading, a visit, an
invitation, a request or a circle), so a tap opens that very item."""

import logging
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from uuid import UUID

from sqlalchemy import select, update

from app import metrics
from app.background import run_later
from app.database import transaction
from app.extensions import get_clock, get_push_sender
from app.models import AccountSession
from app.push.sender import NO_DEVICE, PushMessage, SENT

log = logging.getLogger(__name__)


Target = tuple[tuple[str, str], ...]


def dose_target(circle_id: UUID | str, schedule_id, day) -> Target:
    """A dose: its circle, its schedule and its day."""
    return (
        ("circle_id", str(circle_id)),
        ("schedule_id", str(schedule_id)),
        ("scheduled_on", _day(day)),
    )


def measurement_target(
    circle_id: UUID | str, version_id, day, time_of_day: str
) -> Target:
    """A reading time: its circle, its plan's version, its day and time."""
    return (
        ("circle_id", str(circle_id)),
        ("plan_version_id", str(version_id)),
        ("scheduled_on", _day(day)),
        ("time_of_day", time_of_day),
    )


def appointment_target(circle_id: UUID | str, appointment_id) -> Target:
    """A visit: its circle and its id."""
    return (
        ("circle_id", str(circle_id)),
        ("appointment_id", str(appointment_id)),
    )


def circle_target(circle_id: UUID | str) -> Target:
    """A circle, opened on its «اليوم»."""
    return (("circle_id", str(circle_id)),)


def request_target(request_id) -> Target:
    """A circle request on the bell."""
    return (("request_id", str(request_id)),)


def invitation_target(invitation_id) -> Target:
    """An invitation on the bell."""
    return (("invitation_id", str(invitation_id)),)


def _day(day) -> str:
    return day.isoformat() if isinstance(day, date) else str(day)


_COUNTERS = {SENT: "push.sent", NO_DEVICE: "push.no_device"}


def send_to_accounts(
    sender,
    accounts: Iterable[UUID],
    message: PushMessage,
    *,
    reminder: bool = False,
) -> None:
    """Send to each account that has a live sign-in, counting every result;
    then end the sign-ins whose phone deleted the app. A `reminder` goes
    only to the phones whose app asked for the server's reminders, and
    never to the account as a whole, which reaches the others too."""
    query = select(
        AccountSession.account_id, AccountSession.push_subscription_id
    ).where(
        AccountSession.account_id.in_(list(accounts)),
        AccountSession.revoked_at.is_(None),
    )
    if reminder:
        query = query.where(
            AccountSession.server_reminders.is_(True),
            AccountSession.push_subscription_id.is_not(None),
        )
    with transaction() as session:
        live = session.execute(query).all()
    phones: dict[UUID, set[str]] = {}
    for account_id, subscription_id in live:
        known = phones.setdefault(account_id, set())
        if subscription_id is not None:
            known.add(str(subscription_id))
    # To the phones themselves: an account's external id reaches nothing
    # when the app's OneSignal.login did not take.
    for account_id in sorted(phones, key=str):
        result = sender.send(str(account_id), message, phones[account_id])
        metrics.increment(_COUNTERS.get(result, "push.failed"))
    deleted: set[str] = set()
    for account_id in sorted(phones, key=str):
        # Only accounts with a phone the server can tie to a sign-in.
        if phones[account_id]:
            deleted |= (
                sender.deleted_apps(str(account_id)) & phones[account_id]
            )
    if deleted:
        sign_out_deleted_apps(deleted)


def sign_out_deleted_apps(subscriptions: set[str]) -> None:
    """End the live sign-ins on the phones whose app was deleted, by their
    OneSignal subscription, as a sign-out would.

    It ends the sign-in that has the subscription now: if the phone signed
    in again since, that sign-in is on the phone whose app is gone.
    """
    with transaction() as session:
        signed_out = session.execute(
            update(AccountSession)
            .where(
                AccountSession.push_subscription_id.in_(
                    [UUID(one) for one in subscriptions]
                ),
                AccountSession.revoked_at.is_(None),
            )
            .values(revoked_at=get_clock().now())
        ).rowcount
    if signed_out:
        metrics.increment("session.signed_out_app_deleted", signed_out)
        log.info("Signed out %d session(s) of a deleted app.", signed_out)


@dataclass(frozen=True)
class Push:
    """A message and the accounts it goes to. A `reminder` (at a task's
    time) goes only to the phones whose app leaves its reminders to the
    server (app/push/reminders.py): the others set their own."""

    account_ids: tuple[UUID, ...]
    message: PushMessage
    reminder: bool = False


def notify(push: Push | None) -> None:
    """Send `push` to the phones of its accounts that are signed in now.
    Nothing here raises."""
    sender = get_push_sender()
    if push is None or not sender.enabled:
        return
    accounts: set[UUID] = set(push.account_ids)
    if not accounts:
        return
    run_later(_deliver, accounts, push.message, push.reminder)


def _deliver(
    accounts: set[UUID], message: PushMessage, reminder: bool = False
) -> None:
    """The background job: send `message` to the signed-in accounts among
    `accounts`, and never raise.
    """
    try:
        send_to_accounts(
            get_push_sender(), accounts, message, reminder=reminder
        )
    except Exception:  # noqa: BLE001 - see the module docstring
        metrics.increment("push.failed")
        log.warning("Push notifications were not sent.", exc_info=True)
