"""Whether the server sends the reminders, and who hears them."""

from collections.abc import Iterable
from uuid import UUID

from flask import current_app
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.extensions import get_push_sender
from app.models import AccountSession


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
