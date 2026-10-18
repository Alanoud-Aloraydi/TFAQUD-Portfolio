"""Protect a circle endpoint.

    @bp.get("/api/v1/circles/<circle_id>/today")
    @require_circle_role(CircleRole.MANAGER, CircleRole.PATIENT)
    def today(circle_id):
        ...

This is how the "selected circle" rule of TFQD-11 is enforced: the circle id is
part of the URL, and the caller must hold one of the listed roles in exactly
that circle. With no roles listed, any member is accepted.
"""

from functools import wraps

from flask import g

from app.auth.decorators import authenticate_request
from app.authz.roles import CircleRole
from app.errors import Forbidden
from app.extensions import get_circle_access


def current_circle_role() -> CircleRole:
    return g.circle_role


def require_circle_role(*allowed: CircleRole):
    def decorator(view):
        @wraps(view)
        def wrapper(*args, **kwargs):
            auth = authenticate_request()
            if "circle_id" not in kwargs:
                # A mistake in the code, not in the request.
                raise RuntimeError("require_circle_role needs a <circle_id> in the URL.")
            role = get_circle_access().role_in(auth.user_id, kwargs["circle_id"])
            # Not a member and wrong role give the same answer, so a caller can
            # not learn which circles exist.
            if role is None or (allowed and role not in allowed):
                raise Forbidden("You do not have access to this circle.")
            g.circle_role = role
            return view(*args, **kwargs)

        return wrapper

    return decorator
