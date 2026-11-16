"""Whose account a number is, and the name a push shows for it."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account


def account_with_phone(session: Session, phone: str) -> UUID | None:
    """The id of the account that signs in with `phone`, or None."""
    return session.scalar(
        select(Account.id).where(Account.phone_number == phone)
    )


def display_name(session: Session, account_id: UUID | None) -> str | None:
    """The name to show for an account: its display name, else its first name;
    None when there is no such account.
    """
    if account_id is None:
        return None
    account = session.get(Account, account_id)
    if account is None:
        return None
    return account.display_name or account.first_name
