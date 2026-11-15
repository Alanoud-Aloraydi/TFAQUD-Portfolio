"""The blueprint of the measurement endpoints and the roles they let in."""

from flask import Blueprint

from app.authz.roles import CircleRole

bp = Blueprint(
    "measurements", __name__, url_prefix="/api/v1/circles/<circle_id>"
)
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)
EDITORS = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)
