"""Send one message to the phones of some accounts, through OneSignal.

Called after the request's transaction has committed, so a push never
announces something that was rolled back, and a push that fails never fails
the request. The sending itself runs after the answer (app/background.py):
no one waits for OneSignal.

Only an account that is signed in somewhere gets it. The app unties its
phone from the account at sign-out (OneSignal `logout`); an account whose
every sign-in ended here (expired, signed out elsewhere) is skipped too,
since its phones may not have heard.
"""

import logging
from collections.abc import Iterable
from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import select

from app import metrics
from app.background import run_later
from app.database import transaction
from app.extensions import get_push_sender
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
    """Send to each account that has a live sign-in, counting every result.
    """
    with transaction() as session:
        signed_in = sorted(
            set(
                session.scalars(
                    select(AccountSession.account_id).where(
                        AccountSession.account_id.in_(list(accounts)),
                        AccountSession.revoked_at.is_(None),
                    )
                )
            ),
            key=str,
        )
    for account_id in signed_in:
        result = sender.send(str(account_id), message)
        metrics.increment(_COUNTERS.get(result, "push.failed"))
