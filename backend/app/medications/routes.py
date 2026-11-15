"""Authorized medication plan and dose-record endpoints.

Each group of endpoints lives in its own file and joins the blueprint when
imported here."""


from app.medications import dose_routes, plan_change_routes, plan_routes
from app.medications.blueprint import bp

__all__ = ["bp", "dose_routes", "plan_change_routes", "plan_routes"]
