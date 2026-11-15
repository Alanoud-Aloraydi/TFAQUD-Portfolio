"""The blueprint of the circle endpoints and the roles they let in."""

from flask import Blueprint

from app.authz.roles import CircleRole

bp = Blueprint("circles", __name__, url_prefix="/api/v1/circles")

MANAGER = CircleRole.MANAGER
# A patient with a linked account can read and edit their own data.
MEMBER = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)
READ_MEMBER = (*MEMBER, CircleRole.MEMBER)
