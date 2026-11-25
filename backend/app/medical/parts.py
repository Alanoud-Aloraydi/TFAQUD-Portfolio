"""The parts of the medical file and of a change to it, and the checks of
their codes and their «other» text."""

from dataclasses import dataclass, field

from app.errors import ValidationFailed


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


def invalid(field_name: str, code: str, message: str) -> ValidationFailed:
    """A validation error that names the field the app should highlight."""
    return ValidationFailed(
        message,
        code=code,
        details=[{"field": field_name, "code": code, "message": message}],
    )


def ordered(chosen, allowed) -> list[str]:
    """Keep the order of the official list, so output never shuffles."""
    return [code for code in allowed if code in chosen]


def check_codes(field_name: str, chosen, allowed) -> None:
    """422 when a code is chosen twice or is not in `allowed`."""
    if len(set(chosen)) != len(chosen):
        raise invalid(
            field_name, "duplicate_choice", "Choose each item once."
        )
    if any(code not in allowed for code in chosen):
        raise invalid(field_name, "unknown_choice", "Unknown choice.")


def check_other(field_name: str, chosen, text: str | None) -> str | None:
    """'other' needs the typed text; the text needs 'other'."""
    text = text.strip() if text else None
    # «أخرى» needs 1 to 100 characters of words; words without «أخرى» are
    # refused.
    if "other" in chosen:
        if not text or len(text) > 100:
            raise invalid(
                field_name,
                "other_text_required",
                "Describe the other item in 1 to 100 characters.",
            )
        return text
    if text:
        raise invalid(
            field_name,
            "other_text_unexpected",
            "Text is only allowed together with 'other'.",
        )
    return None
