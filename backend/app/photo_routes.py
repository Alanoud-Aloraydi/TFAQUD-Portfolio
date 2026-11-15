"""Authorized photo and avatar endpoints for care-circle identities.

Each group of endpoints lives in its own file and joins the blueprint when
imported here."""

from app.photos import (
    account_photo_routes,
    medication_photo_routes,
    patient_photo_routes,
)
from app.photos.blueprint import bp

__all__ = [
    "account_photo_routes",
    "bp",
    "medication_photo_routes",
    "patient_photo_routes",
]
