"""The blueprint of the photo endpoints, the roles they let in, and the
body of choosing an avatar."""

from flask import Blueprint
from pydantic import field_validator

from app.authz.roles import CircleRole
from app.photos import AVATAR_CODES
from app.validation import Dto

bp = Blueprint("photos", __name__, url_prefix="/api/v1")
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)
PATIENT_WRITERS = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


class AvatarRequest(Dto):
    """One selected local avatar asset."""

    avatar_code: str

    @field_validator("avatar_code")
    @classmethod
    def valid_code(cls, value: str) -> str:
        """Accept only an avatar the app offers."""
        if value not in AVATAR_CODES:
            raise ValueError("Unknown avatar code.")
        return value
