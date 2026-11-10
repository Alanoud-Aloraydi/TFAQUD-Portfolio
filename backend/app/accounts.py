"""Batch account lookups shared by features that show who acted."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account


def accounts_by_id(session: Session, ids: set[UUID]) -> dict[UUID, Account]:
    """Return accounts keyed by id, in one query for every id in `ids`."""
    if not ids:
        return {}
    rows = session.scalars(select(Account).where(Account.id.in_(ids)))
    return {row.id: row for row in rows}


def recorder_response(account: Account | None) -> dict | None:
    """Return the compact "who recorded this" shape, or None."""
    if account is None:
        return None
    return {
        "account_id": str(account.id),
        "name": account.display_name,
        "avatar_code": account.avatar_code,
    }
