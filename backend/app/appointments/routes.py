"""Authorized appointment transport endpoints.

Each group of endpoints lives in its own file and joins the blueprint when
imported here."""

from app.appointments import read_routes, status_routes, write_routes
from app.appointments.blueprint import bp

__all__ = ["bp", "read_routes", "status_routes", "write_routes"]
