"""Reading a request id from the app, and the lock on one phone number."""

import hashlib
from uuid import UUID

from sqlalchemy import text


def request_key(value):
    """Treat malformed public identifiers as missing records."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        return None


def lock_phone(session, phone):
    """Serialize phone quota claims, including phones without accounts."""
    digest = hashlib.sha256(phone.encode()).digest()[:8]
    session.execute(
        text("SELECT pg_advisory_xact_lock(:key)"),
        {"key": int.from_bytes(digest, "big", signed=True)},
    )
