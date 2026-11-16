"""Reading the medical profile."""

from sqlalchemy import select

from app.medical.checks import ordered
from app.medical.parts import MedicalProfile
from app.models import CareCircle, PatientAllergy, PatientCondition
from app.models.medical import (
    CONDITION_CODES,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)


class ProfileRead:
    """Reads the profile."""

    def _read_profile(self, patient: CareCircle) -> MedicalProfile:
        """The patient's blood type, conditions and allergies, as saved."""
        profile = MedicalProfile(blood_type=patient.blood_type)
        # Conditions: the circle's status says not answered yet (null),
        # none, or listed; listed gives the codes in the app's order, with
        # the words for «أخرى».
        conditions = self.session.scalars(
            select(PatientCondition).where(
                PatientCondition.care_circle_id == patient.id
            )
        ).all()
        if patient.conditions_status is not None:
            codes = {row.code for row in conditions}
            if patient.conditions_status == "none":
                profile.conditions = {
                    "status": "none",
                    "codes": [],
                    "other": None,
                }
            else:
                other = next(
                    (r.other_text for r in conditions if r.code == "other"),
                    None,
                )
                profile.conditions = {
                    "status": "listed",
                    "codes": ordered(codes, CONDITION_CODES),
                    "other": other,
                }
        # Allergies: the same, with medication and food apart, each with its
        # own words for «أخرى».
        allergies = self.session.scalars(
            select(PatientAllergy).where(
                PatientAllergy.care_circle_id == patient.id
            )
        ).all()
        if patient.allergies_status is not None:
            if patient.allergies_status == "none":
                profile.allergies = {
                    "status": "none",
                    "medication": [],
                    "other_medication": None,
                    "food": [],
                    "other_food": None,
                }
            else:
                medication = {
                    r.code for r in allergies if r.kind == "medication"
                }
                food = {r.code for r in allergies if r.kind == "food"}
                profile.allergies = {
                    "status": "listed",
                    "medication": ordered(
                        medication, MEDICATION_ALLERGY_CODES
                    ),
                    "other_medication": next(
                        (
                            r.other_text
                            for r in allergies
                            if r.kind == "medication" and r.code == "other"
                        ),
                        None,
                    ),
                    "food": ordered(food, FOOD_ALLERGY_CODES),
                    "other_food": next(
                        (
                            r.other_text
                            for r in allergies
                            if r.kind == "food" and r.code == "other"
                        ),
                        None,
                    ),
                }
        return profile
