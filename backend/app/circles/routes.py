"""Care circles: create, read, rename, leave, delete; the patient's data;
invitations to manage a circle; the medical file and emergency contacts.

Every route with a circle id in its URL is protected by
`require_circle_role`. A caller who is not in the circle, and a circle that
does not exist, both get the same 403 (see app/authz/decorators.py).

Each group of endpoints lives in its own file and joins the blueprint when
imported here."""

from app.circles import (
    circle_routes,
    contact_routes,
    creation_routes,
    invitation_routes,
    medical_routes,
    member_routes,
)
from app.circles.blueprint import bp

__all__ = [
    "bp",
    "circle_routes",
    "contact_routes",
    "creation_routes",
    "invitation_routes",
    "medical_routes",
    "member_routes",
]
