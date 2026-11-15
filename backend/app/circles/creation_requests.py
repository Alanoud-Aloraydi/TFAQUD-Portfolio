"""Requests to create a circle for a patient who has an account.

The person who wants to care sends a request to the patient's phone number.
The patient accepts or declines (consent). After accepting, the patient
completes the basic data, and only then is the circle created.

The endpoints live in their own files and join the blueprint when imported
here."""

from app.circles import request_completion_routes, request_routes
from app.circles.request_blueprint import bp

__all__ = ["bp", "request_completion_routes", "request_routes"]
