"""The account store in memory: for tests and for a local server
without a database."""

import threading
import uuid
from dataclasses import replace
from datetime import date, datetime

from app.users.store import UserStore
from app.users.user import User


class InMemoryUserStore(UserStore):
    """The accounts in memory, behind one lock: for tests and for a local
    server without a database.
    """

    def __init__(self):
        """No accounts yet; one map by id, one by phone number."""
        self._lock = threading.Lock()
        self._by_id: dict[str, User] = {}
        self._id_by_phone: dict[str, str] = {}

    def get_or_create_by_phone(
        self, phone: str, now: datetime
    ) -> tuple[User, bool]:
        """The account of `phone`, made now when there is none; True as the
        second value when this call made it.
        """
        with self._lock:
            existing_id = self._id_by_phone.get(phone)
            if existing_id is not None:
                return self._by_id[existing_id], False
            user = User(id=uuid.uuid4().hex, phone=phone, created_at=now)
            self._by_id[user.id] = user
            self._id_by_phone[phone] = user.id
            return user, True

    def get(self, user_id: str) -> User | None:
        """The account with this id, or None."""
        with self._lock:
            return self._by_id.get(user_id)

    def update_profile(
        self,
        user_id: str,
        first_name: str,
        last_name: str,
        display_name: str,
        birth_date: date | None = None,
        city: str | None = None,
    ) -> User | None:
        """Save the names, and the birth date and city when given; None when
        there is no such account.
        """
        with self._lock:
            user = self._by_id.get(user_id)
            if user is None:
                return None
            user = replace(
                user,
                first_name=first_name,
                last_name=last_name,
                display_name=display_name,
                birth_date=birth_date or user.birth_date,
                city=city or user.city,
            )
            self._by_id[user_id] = user
            return user
