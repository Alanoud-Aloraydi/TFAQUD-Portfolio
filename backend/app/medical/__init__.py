"""Medical profile and emergency contacts of a patient.

Everything here runs inside a transaction that the caller owns, like
`CareService`. The class reuses the locking helpers of `CareService`, so the
lock order stays the same everywhere: the account first, then the circle.

Who may read or change medical data of a circle:
  - every current manager of the circle;
  - the patient, when the patient has an account linked to the circle."""

from app.medical.parts import (
    MAX_EMERGENCY_CONTACTS,
    UNSET,
    Allergies,
    Conditions,
    MedicalProfile,
    MedicalUpdate,
)
from app.medical.service import MedicalService

__all__ = [
    "Allergies",
    "Conditions",
    "MAX_EMERGENCY_CONTACTS",
    "MedicalProfile",
    "MedicalService",
    "MedicalUpdate",
    "UNSET",
]
