"""Account values and the storage interface used by authentication.

Profiles remain incomplete until all three names are saved. The in-memory
implementation supports local tests; PostgresUserStore persists accounts."""

from abc import ABC, abstractmethod
from datetime import date, datetime

from app.users.user import User


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
