"""Where sessions are kept.

A session is one sign-in. It starts when the user signs in and ends only
when it is signed out: by the user, by deleting the account, or by the
server when the app was deleted from the phone. It has no end date.

`SessionStore` is what every store does; `PostgresSessionStore` keeps them
in the `account_session` table, `InMemorySessionStore` in memory, for tests
and for a local server without a database."""

import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import datetime
from uuid import UUID

from sqlalchemy import func, select, update

from app.database import transaction
from app.models import AccountSession


@dataclass(frozen=True)
class SessionRecord:
    """One sign-in as the server keeps it: who, the hash of its refresh token,
    when it started, and when it was signed out.
    """

    id: str
    user_id: str
    refresh_token_hash: str
    created_at: datetime
    revoked_at: datetime | None = None

    @property
    def is_revoked(self) -> bool:
        """Whether this sign-in was ended."""
        return self.revoked_at is not None


class SessionStore(ABC):
    """Where sign-in sessions are kept."""

    # Keep a new session.
    @abstractmethod
    def add(self, record: SessionRecord) -> None: ...

    # The session with this id, or None.
    @abstractmethod
    def get(self, session_id: str) -> SessionRecord | None: ...

    # The session whose refresh token has this hash, or None.
    @abstractmethod
    def get_by_refresh_hash(
        self, refresh_token_hash: str
    ) -> SessionRecord | None: ...

    @abstractmethod
    def revoke(self, session_id: str, at: datetime) -> bool:
        """Mark the session revoked. Returns False if there is no such session.

        Revoking a session that is already revoked is allowed and keeps the
        first revocation time.
        """


class InMemorySessionStore(SessionStore):
    """The sessions in memory, behind one lock: for tests and for a local
    server without a database.
    """

    def __init__(self):
        """No sessions yet; one map by id, one by refresh-token hash."""
        self._lock = threading.Lock()
        self._by_id: dict[str, SessionRecord] = {}
        self._id_by_hash: dict[str, str] = {}

    def add(self, record: SessionRecord) -> None:
        """Keep the session under its id and its refresh-token hash."""
        with self._lock:
            self._by_id[record.id] = record
            self._id_by_hash[record.refresh_token_hash] = record.id

    def get(self, session_id: str) -> SessionRecord | None:
        """The session with this id, or None."""
        with self._lock:
            return self._by_id.get(session_id)

    def get_by_refresh_hash(
        self, refresh_token_hash: str
    ) -> SessionRecord | None:
        """The session whose refresh token has this hash, or None."""
        with self._lock:
            session_id = self._id_by_hash.get(refresh_token_hash)
            return self._by_id.get(session_id) if session_id else None

    def revoke(self, session_id: str, at: datetime) -> bool:
        """End the session once (a second sign-out keeps the first time); False
        when it is unknown.
        """
        with self._lock:
            record = self._by_id.get(session_id)
            if record is None:
                return False
            if not record.is_revoked:
                self._by_id[session_id] = replace(record, revoked_at=at)
            return True


def _record(row):
    """Detach stored values from the ORM transaction."""
    if row is None:
        return None
    return SessionRecord(
        id=row.id.hex,
        user_id=row.account_id.hex,
        refresh_token_hash=row.refresh_token_hash,
        created_at=row.created_at,
        revoked_at=row.revoked_at,
    )


class PostgresSessionStore(SessionStore):
    """Persist independent sessions and preserve the first revocation time."""

    def add(self, record):
        """Keep a new session row."""
        with transaction() as session:
            session.add(
                AccountSession(
                    id=UUID(record.id),
                    account_id=UUID(record.user_id),
                    refresh_token_hash=record.refresh_token_hash,
                    created_at=record.created_at,
                    revoked_at=record.revoked_at,
                )
            )
            session.flush()

    def get(self, session_id):
        """The session with this id, or None (also for an id that is not a
        UUID).
        """
        try:
            key = UUID(session_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with transaction() as session:
            return _record(session.get(AccountSession, key))

    def get_by_refresh_hash(self, refresh_token_hash):
        """The session whose refresh token has this hash, or None."""
        with transaction() as session:
            return _record(
                session.scalar(
                    select(AccountSession).where(
                        AccountSession.refresh_token_hash == refresh_token_hash
                    )
                )
            )

    def revoke(self, session_id, at):
        """End the session once, keeping the first time; False when it is
        unknown.
        """
        # An id that is not a UUID is no session; a second sign-out keeps the
        # first time.
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
