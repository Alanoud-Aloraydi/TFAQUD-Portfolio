"""Where sessions are kept.

A session is one sign-in. It starts when the user signs in and ends when the
user signs out (or after the refresh token's lifetime). The server keeps one
record per session; this is what makes sign-out real: the record is marked
revoked, and every later request that depends on it is refused.

`SessionStore` is the interface. PostgresSessionStore persists sessions across
workers and restarts. InMemorySessionStore is reserved for isolated tests.

The refresh token itself is never stored, only its SHA-256 hash. If the table
leaked, the hashes could not be used to refresh a session.
"""

import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import datetime


@dataclass(frozen=True)
class SessionRecord:
    """One sign-in as the server keeps it: who, the hash of its refresh token,
    until when, and when it was signed out.
    """

    id: str
    user_id: str
    refresh_token_hash: str
    created_at: datetime
    refresh_expires_at: datetime
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
