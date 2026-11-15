"""The blueprint of the circle-request endpoints."""

from flask import Blueprint

bp = Blueprint(
    "creation_requests", __name__, url_prefix="/api/v1/circle-requests"
)

NOT_FOUND = "The circle request does not exist."
