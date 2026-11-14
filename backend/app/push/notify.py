"""Send one message to the phones of some accounts, through OneSignal.

Called after the request's transaction has committed, so a push never
announces something that was rolled back, and a push that fails never fails
the request. The sending itself runs after the answer (app/background.py):
no one waits for OneSignal.

Only an account that is signed in somewhere gets it. The app unties its
phone from the account at sign-out (OneSignal `logout`); an account whose
every sign-in ended here (expired, signed out elsewhere) is skipped too,
since its phones may not have heard.

A deleted app signs itself out here. A phone tells no one when its app is
deleted, but Apple or Google then refuse its token, and OneSignal marks
that phone's subscription (sender.APP_DELETED). Each sign-in keeps its
phone's subscription (routes.py); after sending, the server asks OneSignal
about the phones of the accounts it sent to, and ends the sign-ins whose
phone deleted the app, as a sign-out would. OneSignal learns of it only
from sends (two or three after the deletion), and Apple can take days.
"""

import logging
from collections.abc import Iterable
from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import select, update

from app import metrics
from app.background import run_later
from app.database import transaction
from app.extensions import get_clock, get_push_sender
from app.models import AccountSession
from app.push.sender import NO_DEVICE, SENT, PushMessage

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class Push:
    """A message and the accounts it goes to."""

    account_ids: tuple[UUID, ...]
    message: PushMessage


def notify(push: Push | None) -> None:
    """Send `push` to the phones of its accounts that are signed in now.
    Nothing here raises."""
    sender = get_push_sender()
    if push is None or not sender.enabled:
        return
    accounts: set[UUID] = set(push.account_ids)
    if not accounts:
        return
    run_later(_deliver, accounts, push.message)


def _deliver(accounts: set[UUID], message: PushMessage) -> None:
    """The background job: send `message` to the signed-in accounts among
    `accounts`, and never raise.
    """
    try:
        _send(get_push_sender(), accounts, message)
    except Exception:  # noqa: BLE001 - see the module docstring
        metrics.increment("push.failed")
        log.warning("Push notifications were not sent.", exc_info=True)


_COUNTERS = {SENT: "push.sent", NO_DEVICE: "push.no_device"}


def _send(sender, accounts: Iterable[UUID], message: PushMessage) -> None:
    """Send to each account that has a live sign-in, counting every result;
    then end the sign-ins whose phone deleted the app."""
    with transaction() as session:
        live = session.execute(
            select(
                AccountSession.account_id,
                AccountSession.push_subscription_id,
            ).where(
                AccountSession.account_id.in_(list(accounts)),
                AccountSession.revoked_at.is_(None),
            )
        ).all()
    phones: dict[UUID, set[str]] = {}
    for account_id, subscription_id in live:
        known = phones.setdefault(account_id, set())
        if subscription_id is not None:
            known.add(str(subscription_id))
    for account_id in sorted(phones, key=str):
        result = sender.send(str(account_id), message)
        metrics.increment(_COUNTERS.get(result, "push.failed"))
    deleted: set[str] = set()
    for account_id in sorted(phones, key=str):
        # Only accounts with a phone the server can tie to a sign-in.
        if phones[account_id]:
            deleted |= (
                sender.deleted_apps(str(account_id)) & phones[account_id]
            )
    if deleted:
        _sign_out_deleted_apps(deleted)


def _sign_out_deleted_apps(subscriptions: set[str]) -> None:
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
