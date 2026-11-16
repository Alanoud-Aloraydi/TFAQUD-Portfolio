"""Where sessions are kept.

A session is one sign-in. It starts when the user signs in and ends only
when it is signed out: by the user, by deleting the account, or by the
server when the app was deleted from the phone. It has no end date. The
server keeps one record per session; this is what makes sign-out real: the
record is marked revoked, and every later request that depends on it is
refused.

`SessionStore` is the interface. PostgresSessionStore persists sessions across
workers and restarts. InMemorySessionStore is reserved for isolated tests.

The refresh token itself is never stored, only its SHA-256 hash. If the table
leaked, the hashes could not be used to refresh a session."""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime


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
