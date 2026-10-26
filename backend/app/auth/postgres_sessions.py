"""PostgreSQL session storage using the existing authentication interface."""

from uuid import UUID

from sqlalchemy import func, select, update

from app.auth.store import SessionRecord, SessionStore
from app.database import transaction
from app.models import AccountSession


def _record(row):
    """Detach stored values from the ORM transaction."""
    if row is None:
        return None
    return SessionRecord(
        id=row.id.hex,
        user_id=row.account_id.hex,
        refresh_token_hash=row.refresh_token_hash,
        created_at=row.created_at,
        refresh_expires_at=row.refresh_expires_at,
        revoked_at=row.revoked_at,
    )


class PostgresSessionStore(SessionStore):
    """Persist independent sessions and preserve the first revocation time."""

    def add(self, record):
        with transaction() as session:
            session.add(
                AccountSession(
                    id=UUID(record.id),
                    account_id=UUID(record.user_id),
                    refresh_token_hash=record.refresh_token_hash,
                    created_at=record.created_at,
                    refresh_expires_at=record.refresh_expires_at,
                    revoked_at=record.revoked_at,
                )
            )
            session.flush()

    def get(self, session_id):
        try:
            key = UUID(session_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with transaction() as session:
            return _record(session.get(AccountSession, key))

    def get_by_refresh_hash(self, refresh_token_hash):
        with transaction() as session:
            return _record(
                session.scalar(
                    select(AccountSession).where(
                        AccountSession.refresh_token_hash == refresh_token_hash
                    )
                )
            )

    def revoke(self, session_id, at):
        try:
            key = UUID(session_id)
        except (ValueError, TypeError, AttributeError):
            return False
        with transaction() as session:
            return (
                session.execute(
                    update(AccountSession)
                    .where(AccountSession.id == key)
                    .values(
                        revoked_at=func.coalesce(AccountSession.revoked_at, at)
                    )
                ).rowcount
                > 0
            )
