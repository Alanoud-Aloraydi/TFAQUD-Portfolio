"""The checks of the codes and the «other» text of a change."""

from app.errors import ValidationFailed


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
