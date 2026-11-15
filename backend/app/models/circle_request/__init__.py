"""Circle requests and circle invitations: the two ways someone joins care.

A circle request asks a phone number to become the patient of a new circle
(acceptance is consent; completion creates the circle). A circle
invitation asks a phone number to manage an existing circle."""

from app.models.circle_request.formats import PHONE_FORMAT
from app.models.circle_request.invitation import CareCircleInvitation
from app.models.circle_request.request import CareCircleRequest

__all__ = [
    "CareCircleInvitation",
    "CareCircleRequest",
    "PHONE_FORMAT",
]
