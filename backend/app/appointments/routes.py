"""Authorized appointment transport endpoints.

Each group of endpoints lives in its own file and joins the blueprint when
imported here."""

from app.appointments import (
    outcome_routes,
    read_routes,
    status_routes,
    write_routes,
)
from app.appointments.blueprint import bp

__all__ = [
    "bp",
    "outcome_routes",
    "read_routes",
    "status_routes",
    "write_routes",
]
