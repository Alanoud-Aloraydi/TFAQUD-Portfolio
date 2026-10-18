"""Decorators that protect endpoints.

    @require_auth           the caller must be signed in
    current_auth()          who the caller is (user id and session id)
"""

from functools import wraps

from flask import g, request

from app.auth.tokens import AccessClaims
from app.errors import Unauthorized
from app.extensions import get_session_service


def authenticate_request() -> AccessClaims:
    """Read the `Authorization: Bearer <token>` header and check it."""
    header = request.headers.get("Authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise Unauthorized(
            "Send the access token as 'Authorization: Bearer <token>'.",
            code="missing_token",
        )
    claims = get_session_service().authenticate(token.strip())
    g.auth = claims
    return claims


def current_auth() -> AccessClaims:
    return g.auth


def require_auth(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        authenticate_request()
        return view(*args, **kwargs)

    return wrapper
