"""Sending one message to signed-in accounts, counting each result, and
ending the sign-ins of phones whose app was deleted."""

import logging
from collections.abc import Iterable
from uuid import UUID

from sqlalchemy import select, update

from app import metrics
from app.database import transaction
from app.extensions import get_clock
from app.models import AccountSession
from app.push.sender import NO_DEVICE, SENT, PushMessage

log = logging.getLogger(__name__)

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
