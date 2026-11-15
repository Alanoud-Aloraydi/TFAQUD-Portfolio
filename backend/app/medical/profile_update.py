"""Changing the medical profile: only the parts the request names."""

from uuid import UUID

from sqlalchemy import delete

from app.medical.checks import invalid
from app.medical.parts import (
    UNSET,
    Allergies,
    Conditions,
    MedicalProfile,
    MedicalUpdate,
)
from app.models import PatientAllergy, PatientCondition
from app.models.medical import BLOOD_TYPES


class ProfileUpdate:
    """Changes the profile."""

    def update_profile(
        self, actor_id: UUID, circle_id: UUID, update: MedicalUpdate
    ) -> MedicalProfile:
        """Replace the parts named in `update`, all or nothing."""
        # Validate first, so a bad request never touches the database.
        rows = self._rows_for(update)
        if (
            update.blood_type is not UNSET
            and update.blood_type is not None
            and update.blood_type not in BLOOD_TYPES
        ):
            raise invalid(
                "blood_type", "unknown_choice", "Unknown blood type."
            )
        # Lock the patient, then replace only the parts the request named: a
        # part's old rows go and its new rows come, in one transaction.
        patient = self._open_for(actor_id, circle_id, lock=True)
        if update.blood_type is not UNSET:
            patient.blood_type = update.blood_type
        if "conditions" in rows:
            patient.conditions_status, items = rows["conditions"]
            self.session.execute(
                delete(PatientCondition).where(
                    PatientCondition.care_circle_id == patient.id
                )
            )
            self.session.add_all(
                PatientCondition(
                    care_circle_id=patient.id, code=code, other_text=text
                )
                for code, text in items
            )
        if "allergies" in rows:
            patient.allergies_status, items = rows["allergies"]
            self.session.execute(
                delete(PatientAllergy).where(
                    PatientAllergy.care_circle_id == patient.id
                )
            )
            self.session.add_all(
                PatientAllergy(
                    care_circle_id=patient.id,
                    kind=kind,
                    code=code,
                    other_text=text,
                )
                for kind, code, text in items
            )
        self.session.flush()
        return self._read_profile(patient)

    def _rows_for(self, update: MedicalUpdate) -> dict:
        """Turn the requested parts into (status, rows), or raise a field
        error; a part cleared to unknown is (None, [])."""
        rows = {}
        if isinstance(update.conditions, Conditions):
            rows["conditions"] = (
                update.conditions.status,
                self._condition_rows(update.conditions),
            )
        elif update.conditions is None:
            rows["conditions"] = (None, [])
        if isinstance(update.allergies, Allergies):
            rows["allergies"] = (
                update.allergies.status,
                self._allergy_rows(update.allergies),
            )
        elif update.allergies is None:
            rows["allergies"] = (None, [])
        return rows
