"""The blueprint of the visit endpoints, the roles they let in, and the
body of a visit paper."""

from uuid import UUID

from flask import Blueprint
from pydantic import Field

from app.authz.roles import CircleRole
from app.errors import NotFound
from app.validation import Dto

bp = Blueprint(
    "appointment_visits", __name__,
    url_prefix=(
        "/api/v1/circles/<circle_id>/appointments/"
        "<appointment_id>/visit"
    ),
)
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)


class VisitRequest(Dto):
    """The three editable fields visible in the visit paper."""

    summary: str | None = Field(default=None, max_length=2000)
    recommendations: str | None = Field(default=None, max_length=2000)
    follow_up: str | None = Field(default=None, max_length=500)


def parse_uuid(value: str) -> UUID:
    """Hide malformed identifiers behind the not-found response."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None
