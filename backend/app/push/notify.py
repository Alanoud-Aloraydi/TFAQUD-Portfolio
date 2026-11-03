"""Send one message to every signed-in phone of some accounts.

Called after the request's transaction has committed, so a push never
announces something that was rolled back, and a push that fails never fails
the request.
"""

import logging
from collections.abc import Iterable
from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import delete, select

from app.database import transaction
from app.extensions import get_clock, get_push_sender
from app.models import AccountSession, PushDevice
from app.push.sender import GONE, PushMessage

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class Push:
    """A message and the accounts it goes to."""

    account_ids: tuple[UUID, ...]
    message: PushMessage


def notify(push: Push | None) -> None:
    """Send `push` to the phones of its accounts that are signed in now.

    Tokens Apple no longer knows are deleted. Nothing here raises.
    """
    sender = get_push_sender()
    if push is None or not sender.enabled:
        return
    accounts: set[UUID] = set(push.account_ids)
    if not accounts:
        return
    try:
        _send(sender, accounts, push.message)
    except Exception:  # noqa: BLE001 - see the module docstring
        log.warning("Push notifications were not sent.", exc_info=True)


def _send(sender, accounts: Iterable[UUID], message: PushMessage) -> None:
    now = get_clock().now()
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
                    AccountSession.refresh_expires_at > now,
                )
                .order_by(PushDevice.token)
            )
        )
    gone = [token for token in tokens if sender.send(token, message) == GONE]
    if gone:
        with transaction() as session:
            session.execute(
                delete(PushDevice).where(PushDevice.token.in_(gone))
            )
