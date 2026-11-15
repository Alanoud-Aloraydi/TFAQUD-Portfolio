"""The medical file of a circle's patient: conditions, allergies, contacts.

The code lists below are the only values the API accepts, and the database
checks the same lists. Whether the patient has none of them is not a row:
it is `care_circle.conditions_status` / `allergies_status` (migration 0038)."""

from app.models.circle import BLOOD_TYPES
from app.models.medical.allergy import PatientAllergy
from app.models.medical.codes import (
    CONDITION_CODES,
    CONTACT_RELATIONS,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)
from app.models.medical.condition import PatientCondition
from app.models.medical.contact import EmergencyContact

__all__ = [
    "BLOOD_TYPES",
    "CONDITION_CODES",
    "CONTACT_RELATIONS",
    "EmergencyContact",
    "FOOD_ALLERGY_CODES",
    "MEDICATION_ALLERGY_CODES",
    "PatientAllergy",
    "PatientCondition",
]
