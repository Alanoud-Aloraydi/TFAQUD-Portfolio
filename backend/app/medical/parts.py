"""The parts of the medical file, and of a change to it."""

from dataclasses import dataclass, field

MAX_EMERGENCY_CONTACTS = 5


class Unset:
    """Marks a part of the profile that the request did not mention."""

    def __repr__(self):
        """Show as UNSET in logs and tests."""
        return "UNSET"


UNSET = Unset()


@dataclass(frozen=True)
class Conditions:
    """Chronic conditions. status is 'none' or 'listed'."""

    status: str
    codes: tuple[str, ...] = ()
    other: str | None = None


@dataclass(frozen=True)
class Allergies:
    """Allergies. status is 'none' or 'listed'."""

    status: str
    medication: tuple[str, ...] = ()
    other_medication: str | None = None
    food: tuple[str, ...] = ()
    other_food: str | None = None


@dataclass(frozen=True)
class MedicalUpdate:
    """The parts of the profile to change.

    A part left as UNSET is not touched. A part set to None is cleared, which
    means "unknown" again (the app has not asked, or the user skipped it).
    """

    blood_type: str | None | Unset = UNSET
    conditions: Conditions | None | Unset = UNSET
    allergies: Allergies | None | Unset = UNSET


@dataclass
class MedicalProfile:
    """The stored profile, in the shape the API returns."""

    blood_type: str | None = None
    conditions: dict = field(
        default_factory=lambda: {
            "status": "unknown",
            "codes": [],
            "other": None,
        }
    )
    allergies: dict = field(
        default_factory=lambda: {
            "status": "unknown",
            "medication": [],
            "other_medication": None,
            "food": [],
            "other_food": None,
        }
    )
