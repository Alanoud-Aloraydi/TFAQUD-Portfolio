"""Account values and the storage interface used by authentication.

Profiles remain incomplete until all three names are saved. The in-memory
implementation supports local tests; PostgresUserStore persists accounts.
"""

import threading
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, replace
from datetime import date, datetime


@dataclass(frozen=True)
class User:
    """One account as the sign-in code sees it: the phone number and the
    profile the person filled in.
    """

    id: str
    phone: str  # international format, +9665XXXXXXXX
    created_at: datetime
    first_name: str | None = None
    last_name: str | None = None
    display_name: str | None = None
    app_mode: str | None = None
    birth_date: date | None = None
    city: str | None = None

    @property
    def profile_complete(self) -> bool:
        """True once the three names are saved; the app then skips onboarding.

        Birth date and city are left out on purpose: accounts made before
        onboarding asked for them give them when they create their own
        circle.
        """
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
            "app_mode": self.app_mode,
            "birth_date": (
                self.birth_date.isoformat() if self.birth_date else None
            ),
            "city": self.city,
        }


class UserStore(ABC):
    """Where accounts are found by phone number, made, read and given a
    profile, by the auth and users routes.

    PostgresUserStore backs the app; InMemoryUserStore backs unit tests.
    The profile endpoint writes through update_profile.
    """

    @abstractmethod
    def get_or_create_by_phone(
        self, phone: str, now: datetime
    ) -> tuple[User, bool]:
        """Return the user of this phone number, creating it if there is none.

        The second value is True when this call created the user. Two calls at
        the same time for the same phone number must give the same user.
        """

    # The account with this id, or None.
    @abstractmethod
    def get(self, user_id: str) -> User | None: ...

    @abstractmethod
    def update_profile(
        self,
        user_id: str,
        first_name: str,
        last_name: str,
        display_name: str,
        birth_date: date | None = None,
        city: str | None = None,
    ) -> User | None:
        """Replace all three names, or return None for an unknown account.

        A birth date or city that is None keeps the saved one: the account
        page sends only the names.
        """


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
