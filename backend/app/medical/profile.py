"""The medical profile: reading it, and changing only the parts a request
names (the patient's conditions and allergies, each a row)."""

from uuid import UUID

from sqlalchemy import delete, select

from app.medical.parts import (
    Allergies,
    Conditions,
    MedicalProfile,
    MedicalUpdate,
    UNSET,
    check_codes,
    check_other,
    invalid,
    ordered,
)
from app.models import CareCircle, PatientAllergy, PatientCondition
from app.models.circle import BLOOD_TYPES
from app.models.medical import (
    CONDITION_CODES,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)


class ProfileChanges:
    """Reads the medical profile, and changes only the parts a request
    names."""

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

    # Changes the profile.
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

    # Makes the condition and allergy rows.
    @staticmethod
    def _condition_rows(value: Conditions) -> list[tuple]:
        """The rows to save for the conditions; «none» cannot come with any
        condition.
        """
        # «None» is the status alone, with no rows.
        if value.status == "none":
            if value.codes or value.other:
                raise invalid(
                    "conditions",
                    "none_is_exclusive",
                    "'No conditions' cannot be combined with other choices.",
                )
            return []
        # A list needs one item at least, known codes each once, and words when
        # «أخرى» is chosen; the rows in the app's order.
        if value.status != "listed":
            raise invalid("conditions", "unknown_choice", "Unknown status.")
        if not value.codes:
            raise invalid(
                "conditions", "empty_selection", "Choose at least one item."
            )
        check_codes("conditions", value.codes, CONDITION_CODES)
        other = check_other("conditions", value.codes, value.other)
        return [
            (code, other if code == "other" else None)
            for code in ordered(value.codes, CONDITION_CODES)
        ]

    @staticmethod
    def _allergy_rows(value: Allergies) -> list[tuple]:
        """The rows to save for the allergies; «none» cannot come with any
        allergy.
        """
        # «None» is one row, alone.
        if value.status == "none":
            if (
                value.medication
                or value.food
                or value.other_medication
                or (value.other_food)
            ):
                raise invalid(
                    "allergies",
                    "none_is_exclusive",
                    "'No allergies' cannot be combined with other choices.",
                )
            return []
        # A list needs one item at least, known codes each once, and words for
        # each «أخرى» chosen.
        if value.status != "listed":
            raise invalid("allergies", "unknown_choice", "Unknown status.")
        if not value.medication and not value.food:
            raise invalid(
                "allergies", "empty_selection", "Choose at least one item."
            )
        check_codes(
            "allergies.medication", value.medication, MEDICATION_ALLERGY_CODES
        )
        check_codes("allergies.food", value.food, FOOD_ALLERGY_CODES)
        other_medication = check_other(
            "allergies.other_medication",
            value.medication,
            value.other_medication,
        )
        other_food = check_other(
            "allergies.other_food", value.food, value.other_food
        )
        # The rows in the app's order: medication first, then food.
        rows = [
            ("medication", code, other_medication if code == "other" else None)
            for code in ordered(value.medication, MEDICATION_ALLERGY_CODES)
        ]
        rows += [
            ("food", code, other_food if code == "other" else None)
            for code in ordered(value.food, FOOD_ALLERGY_CODES)
        ]
        return rows
