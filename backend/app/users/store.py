"""Account values and the storage interface used by authentication.

Profiles remain incomplete until all three names are saved. The in-memory
implementation supports local tests; PostgresUserStore persists accounts.
"""

import threading
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import datetime


@dataclass(frozen=True)
class User:
    id: str
    phone: str  # international format, +9665XXXXXXXX
    created_at: datetime
    first_name: str | None = None
    last_name: str | None = None
    display_name: str | None = None

    @property
    def profile_complete(self) -> bool:
        return bool(self.first_name and self.last_name and self.display_name)

    def to_dict(self) -> dict:
        """The user as the API returns it."""
        return {
            "id": self.id,
            "phone_number": self.phone,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "display_name": self.display_name,
            "profile_complete": self.profile_complete,
        }


class UserStore(ABC):
    @abstractmethod
    def get_or_create_by_phone(
        self, phone: str, now: datetime
    ) -> tuple[User, bool]:
        """Return the user of this phone number, creating it if there is none.

        The second value is True when this call created the user. Two calls at
        the same time for the same phone number must give the same user.
        """

    @abstractmethod
    def get(self, user_id: str) -> User | None: ...

    @abstractmethod
    def update_profile(
        self, user_id: str, first_name: str, last_name: str, display_name: str
    ) -> User | None:
        """Replace all three names, or return None for an unknown account."""


class InMemoryUserStore(UserStore):
    def __init__(self):
        self._lock = threading.Lock()
        self._by_id: dict[str, User] = {}
        self._id_by_phone: dict[str, str] = {}

    def get_or_create_by_phone(
        self, phone: str, now: datetime
    ) -> tuple[User, bool]:
        with self._lock:
            existing_id = self._id_by_phone.get(phone)
            if existing_id is not None:
                return self._by_id[existing_id], False
            user = User(id=uuid.uuid4().hex, phone=phone, created_at=now)
            self._by_id[user.id] = user
            self._id_by_phone[phone] = user.id
            return user, True

    def get(self, user_id: str) -> User | None:
        with self._lock:
            return self._by_id.get(user_id)

    def update_profile(
        self, user_id: str, first_name: str, last_name: str, display_name: str
    ) -> User | None:
        with self._lock:
            user = self._by_id.get(user_id)
            if user is None:
                return None
            user = replace(
                user,
                first_name=first_name,
                last_name=last_name,
                display_name=display_name,
            )
            self._by_id[user_id] = user
            return user
