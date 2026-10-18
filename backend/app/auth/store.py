"""Where sessions are kept.

A session is one sign-in. It starts when the user signs in and ends when the
user signs out (or after the refresh token's lifetime). The server keeps one
record per session; this is what makes sign-out real: the record is marked
revoked, and every later request that depends on it is refused.

`SessionStore` is the interface. `InMemorySessionStore` is the only
implementation for now. It is correct, but it forgets everything on restart and
is not shared between server processes, so it is for development and tests
only. A PostgreSQL store replaces it once the schema from TFQD-7 exists.

The refresh token itself is never stored, only its SHA-256 hash. If the table
leaked, the hashes could not be used to refresh a session.
"""

import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import datetime


@dataclass(frozen=True)
class SessionRecord:
    id: str
    user_id: str
    refresh_token_hash: str
    created_at: datetime
    refresh_expires_at: datetime
    revoked_at: datetime | None = None

    @property
    def is_revoked(self) -> bool:
        return self.revoked_at is not None


class SessionStore(ABC):
    @abstractmethod
    def add(self, record: SessionRecord) -> None: ...

    @abstractmethod
    def get(self, session_id: str) -> SessionRecord | None: ...

    @abstractmethod
    def get_by_refresh_hash(self, refresh_token_hash: str) -> SessionRecord | None: ...

    @abstractmethod
    def revoke(self, session_id: str, at: datetime) -> bool:
        """Mark the session revoked. Returns False if there is no such session.

        Revoking a session that is already revoked is allowed and keeps the
        first revocation time.
        """


class InMemorySessionStore(SessionStore):
    def __init__(self):
        self._lock = threading.Lock()
        self._by_id: dict[str, SessionRecord] = {}
        self._id_by_hash: dict[str, str] = {}

    def add(self, record: SessionRecord) -> None:
        with self._lock:
            self._by_id[record.id] = record
            self._id_by_hash[record.refresh_token_hash] = record.id

    def get(self, session_id: str) -> SessionRecord | None:
        with self._lock:
            return self._by_id.get(session_id)

    def get_by_refresh_hash(self, refresh_token_hash: str) -> SessionRecord | None:
        with self._lock:
            session_id = self._id_by_hash.get(refresh_token_hash)
            return self._by_id.get(session_id) if session_id else None

    def revoke(self, session_id: str, at: datetime) -> bool:
        with self._lock:
            record = self._by_id.get(session_id)
            if record is None:
                return False
            if not record.is_revoked:
                self._by_id[session_id] = replace(record, revoked_at=at)
            return True
