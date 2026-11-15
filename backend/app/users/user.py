"""One account as the sign-in code and the account endpoints see it."""

from dataclasses import dataclass
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
