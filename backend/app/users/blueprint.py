"""The blueprint of the account endpoints."""

from flask import Blueprint

bp = Blueprint("users", __name__, url_prefix="/api/v1/accounts")
