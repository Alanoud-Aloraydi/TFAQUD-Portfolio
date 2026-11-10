"""Send one message to every signed-in phone of some accounts.

Called after the request's transaction has committed, so a push never
announces something that was rolled back, and a push that fails never fails
the request. The sending itself runs after the answer (app/background.py):
no one waits for Apple.

A deleted app signs itself out here. iOS tells no one when an app is
deleted, but Apple then answers 410 for its token. That ends the sign-in the
token belongs to, as a sign-out would. Apple's answer can come days later,
and a token can also stop when iOS gives the phone a new one; the app sends
its new token every time it opens, which replaces the old one (routes.py),
so only a token no open app still uses can end a sign-in.
"""

import logging
from collections.abc import Iterable
from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import delete, select, update

from app import metrics
from app.background import run_later
from app.database import transaction
from app.extensions import get_clock, get_push_sender
from app.models import AccountSession, PushDevice
from app.push.sender import GONE, SENT, UNREGISTERED, PushMessage

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class Push:
    """A message and the accounts it goes to."""

    account_ids: tuple[UUID, ...]
    message: PushMessage


def notify(push: Push | None) -> None:
    """Send `push` to the phones of its accounts that are signed in now.

    Tokens Apple no longer knows are deleted, and a deleted app's sign-in
    ends. Nothing here raises.
    """
    sender = get_push_sender()
    if push is None or not sender.enabled:
        return
    accounts: set[UUID] = set(push.account_ids)
    if not accounts:
        return
    run_later(_deliver, accounts, push.message)


def _deliver(accounts: set[UUID], message: PushMessage) -> None:
    """The background job: send `message` to the signed-in phones of
    `accounts`, and never raise.
    """
    try:
        _send(get_push_sender(), accounts, message)
    except Exception:  # noqa: BLE001 - see the module docstring
        metrics.increment("push.failed")
        log.warning("Push notifications were not sent.", exc_info=True)


_COUNTERS = {
    SENT: "push.sent",
    GONE: "push.gone",
    UNREGISTERED: "push.unregistered",
}


def _send(sender, accounts: Iterable[UUID], message: PushMessage) -> None:
    """Find the push tokens of the accounts' live sign-ins, send to each phone,
    count every result, and forget the tokens Apple no longer knows.
    """
    # The phones of the accounts' sign-ins that are still live.
    with transaction() as session:
        tokens = list(
            session.scalars(
                select(PushDevice.token)
                .join(
                    AccountSession,
                    AccountSession.id == PushDevice.session_id,
                )
                .where(
                    PushDevice.account_id.in_(list(accounts)),
                    AccountSession.revoked_at.is_(None),
                )
                .order_by(PushDevice.token)
            )
        )
    # Send to each, counting every result.
    gone, deleted_apps = [], []
    for token in tokens:
        result = sender.send(token, message)
        if result == GONE:
            gone.append(token)
        elif result == UNREGISTERED:
            deleted_apps.append(token)
        metrics.increment(_COUNTERS.get(result, "push.failed"))
    if gone or deleted_apps:
        _forget(gone, deleted_apps)


def _forget(gone: list[str], deleted_apps: list[str]) -> None:
    """Delete the tokens Apple no longer knows, and sign out the sessions of
    the deleted apps, in one transaction.

    A session is signed out only while the dead token is still its token:
    if the app sent a new one meanwhile, the app is still there.
    """
    with transaction() as session:
        if deleted_apps:
            signed_out = session.execute(
                update(AccountSession)
                .where(
                    AccountSession.id.in_(
                        select(PushDevice.session_id).where(
                            PushDevice.token.in_(deleted_apps)
                        )
                    ),
                    AccountSession.revoked_at.is_(None),
                )
                .values(revoked_at=get_clock().now())
            ).rowcount
            if signed_out:
                metrics.increment("session.signed_out_by_apple", signed_out)
                log.info(
                    "Signed out %d session(s) of a deleted app.", signed_out
                )
        session.execute(
            delete(PushDevice).where(
                PushDevice.token.in_(gone + deleted_apps)
            )
        )
