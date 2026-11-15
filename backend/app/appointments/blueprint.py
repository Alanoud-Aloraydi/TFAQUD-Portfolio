"""The blueprint of the appointment endpoints and the roles they let in."""

from uuid import UUID

from flask import Blueprint

from app.authz.roles import CircleRole
from app.errors import NotFound

bp = Blueprint(
    "appointments", __name__, url_prefix="/api/v1/circles/<circle_id>"
)
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)


def parse_uuid(value: str) -> UUID:
    """Parse an opaque identifier as a not-found response."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None
