"""The blueprint of the medicine endpoints and the roles they let in."""

from flask import Blueprint

from app.authz.roles import CircleRole

bp = Blueprint(
    "medications",
    __name__,
    url_prefix="/api/v1/circles/<circle_id>",
)

READ_ROLES = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)
RECORD_ROLES = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)
