"""A time as the API writes it."""

from datetime import datetime


def iso_time(value: datetime | None) -> str | None:
    """A time as ISO 8601 text, or None."""
    return value.isoformat() if value else None
