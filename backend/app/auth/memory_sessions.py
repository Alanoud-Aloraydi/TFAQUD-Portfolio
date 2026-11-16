"""The session store in memory: for tests and for a local server
without a database."""

import threading
from dataclasses import replace
from datetime import datetime

from app.auth.store import SessionRecord, SessionStore


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
