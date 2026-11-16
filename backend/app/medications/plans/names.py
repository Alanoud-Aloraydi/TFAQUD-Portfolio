"""The key two medicine names are compared by."""

import unicodedata


def normalize_medication_name(value: str) -> str:
    """Return a conservative comparison key without changing display text."""
    normalized = unicodedata.normalize("NFKC", value)
    return " ".join(normalized.casefold().split())
