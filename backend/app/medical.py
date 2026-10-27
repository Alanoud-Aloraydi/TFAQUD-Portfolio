"""Medical profile and emergency contacts of a patient.

Everything here runs inside a transaction that the caller owns, like
`CareService`. The class reuses the locking helpers of `CareService`, so the
lock order stays the same everywhere: the account first, then the circle.

Who may read or change medical data of a circle:
  - every current manager of the circle;
  - the patient, when the patient has an account linked to the circle.
"""

from dataclasses import dataclass, field
from uuid import UUID

from sqlalchemy import delete, select

from app.care import CareService
from app.errors import NotFound, ValidationFailed
from app.models import EmergencyContact, Patient, PatientAllergy
from app.models import PatientCondition
from app.models.medical import (
    BLOOD_TYPES,
    CONDITION_CODES,
    CONTACT_RELATIONS,
    FOOD_ALLERGY_CODES,
    MEDICATION_ALLERGY_CODES,
)

MAX_EMERGENCY_CONTACTS = 5


class _Unset:
    """Marks a part of the profile that the request did not mention."""

    def __repr__(self):
        return "UNSET"


UNSET = _Unset()


@dataclass(frozen=True)
class Conditions:
    """Chronic conditions. status is 'none' or 'listed'."""

    status: str
    codes: tuple[str, ...] = ()
    other: str | None = None


@dataclass(frozen=True)
class Allergies:
    """Allergies. status is 'none' or 'listed'."""

    status: str
    medication: tuple[str, ...] = ()
    other_medication: str | None = None
    food: tuple[str, ...] = ()
    other_food: str | None = None


@dataclass(frozen=True)
class MedicalUpdate:
    """The parts of the profile to change.

    A part left as UNSET is not touched. A part set to None is cleared, which
    means "unknown" again (the app has not asked, or the user skipped it).
    """

    blood_type: str | None | _Unset = UNSET
    conditions: Conditions | None | _Unset = UNSET
    allergies: Allergies | None | _Unset = UNSET


@dataclass
class MedicalProfile:
    """The stored profile, in the shape the API returns."""

    blood_type: str | None = None
    conditions: dict = field(
        default_factory=lambda: {
            "status": "unknown",
            "codes": [],
            "other": None,
        }
    )
    allergies: dict = field(
        default_factory=lambda: {
            "status": "unknown",
            "medication": [],
            "other_medication": None,
            "food": [],
            "other_food": None,
        }
    )


def _invalid(field_name: str, code: str, message: str) -> ValidationFailed:
    """A validation error that names the field the app should highlight."""
    return ValidationFailed(
        message,
        code=code,
        details=[{"field": field_name, "code": code, "message": message}],
    )


def _ordered(chosen, allowed) -> list[str]:
    """Keep the order of the official list, so output never shuffles."""
    return [code for code in allowed if code in chosen]


def _check_codes(field_name: str, chosen, allowed) -> None:
    if len(set(chosen)) != len(chosen):
        raise _invalid(
            field_name, "duplicate_choice", "Choose each item once."
        )
    if any(code not in allowed for code in chosen):
        raise _invalid(field_name, "unknown_choice", "Unknown choice.")


def _check_other(field_name: str, chosen, text: str | None) -> str | None:
    """'other' needs the typed text; the text needs 'other'."""
    text = text.strip() if text else None
    if "other" in chosen:
        if not text or len(text) > 100:
            raise _invalid(
                field_name,
                "other_text_required",
                "Describe the other item in 1 to 100 characters.",
            )
        return text
    if text:
        raise _invalid(
            field_name,
            "other_text_unexpected",
            "Text is only allowed together with 'other'.",
        )
    return None


class MedicalService(CareService):
    """Medical profile and emergency contacts, with circle-level locking."""

    # ---- access -----------------------------------------------------

    def _open_for(self, actor_id: UUID, circle_id: UUID, *, lock: bool):
        """Check access to the circle's medical data and return the patient.

        Writers lock the account and then the circle, so two edits of the
        same circle run one after the other. Access is checked after the lock,
        because a manager may have left a moment before.
        """
        self._lock_accounts(actor_id)
        if lock:
            self._lock_circle(circle_id)
        patient = self._get_patient(circle_id)
        self.session.refresh(patient)
        if patient.account_id != actor_id:
            self._require_manager(actor_id, circle_id)
        return patient

    # ---- profile ----------------------------------------------------

    def get_file(
        self, actor_id: UUID, circle_id: UUID
    ) -> tuple[Patient, MedicalProfile, list[EmergencyContact]]:
        """Return the patient, the health data and the contacts."""
        patient = self._open_for(actor_id, circle_id, lock=False)
        return patient, self._read_profile(patient), self._contacts(patient)

    def _read_profile(self, patient: Patient) -> MedicalProfile:
        profile = MedicalProfile(blood_type=patient.blood_type)
        conditions = self.session.scalars(
            select(PatientCondition).where(
                PatientCondition.patient_id == patient.id
            )
        ).all()
        if conditions:
            codes = {row.code for row in conditions}
            if codes == {"none"}:
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
                    "codes": _ordered(codes, CONDITION_CODES),
                    "other": other,
                }
        allergies = self.session.scalars(
            select(PatientAllergy).where(
                PatientAllergy.patient_id == patient.id
            )
        ).all()
        if allergies:
            if {row.kind for row in allergies} == {"none"}:
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
                    "medication": _ordered(
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
                    "food": _ordered(food, FOOD_ALLERGY_CODES),
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
            raise _invalid(
                "blood_type", "unknown_choice", "Unknown blood type."
            )
        patient = self._open_for(actor_id, circle_id, lock=True)
        if update.blood_type is not UNSET:
            patient.blood_type = update.blood_type
        if "conditions" in rows:
            self.session.execute(
                delete(PatientCondition).where(
                    PatientCondition.patient_id == patient.id
                )
            )
            self.session.add_all(
                PatientCondition(
                    patient_id=patient.id, code=code, other_text=text
                )
                for code, text in rows["conditions"]
            )
        if "allergies" in rows:
            self.session.execute(
                delete(PatientAllergy).where(
                    PatientAllergy.patient_id == patient.id
                )
            )
            self.session.add_all(
                PatientAllergy(
                    patient_id=patient.id,
                    kind=kind,
                    code=code,
                    other_text=text,
                )
                for kind, code, text in rows["allergies"]
            )
        self.session.flush()
        return self._read_profile(patient)

    def _rows_for(self, update: MedicalUpdate) -> dict:
        """Turn the requested parts into rows, or raise a field error."""
        rows = {}
        if isinstance(update.conditions, Conditions):
            rows["conditions"] = self._condition_rows(update.conditions)
        elif update.conditions is None:
            rows["conditions"] = []
        if isinstance(update.allergies, Allergies):
            rows["allergies"] = self._allergy_rows(update.allergies)
        elif update.allergies is None:
            rows["allergies"] = []
        return rows

    @staticmethod
    def _condition_rows(value: Conditions) -> list[tuple]:
        if value.status == "none":
            if value.codes or value.other:
                raise _invalid(
                    "conditions",
                    "none_is_exclusive",
                    "'No conditions' cannot be combined with other choices.",
                )
            return [("none", None)]
        if value.status != "listed":
            raise _invalid("conditions", "unknown_choice", "Unknown status.")
        if not value.codes:
            raise _invalid(
                "conditions", "empty_selection", "Choose at least one item."
            )
        _check_codes("conditions", value.codes, CONDITION_CODES)
        other = _check_other("conditions", value.codes, value.other)
        return [
            (code, other if code == "other" else None)
            for code in _ordered(value.codes, CONDITION_CODES)
        ]

    @staticmethod
    def _allergy_rows(value: Allergies) -> list[tuple]:
        if value.status == "none":
            if (
                value.medication
                or value.food
                or value.other_medication
                or (value.other_food)
            ):
                raise _invalid(
                    "allergies",
                    "none_is_exclusive",
                    "'No allergies' cannot be combined with other choices.",
                )
            return [("none", "none", None)]
        if value.status != "listed":
            raise _invalid("allergies", "unknown_choice", "Unknown status.")
        if not value.medication and not value.food:
            raise _invalid(
                "allergies", "empty_selection", "Choose at least one item."
            )
        _check_codes(
            "allergies.medication", value.medication, MEDICATION_ALLERGY_CODES
        )
        _check_codes("allergies.food", value.food, FOOD_ALLERGY_CODES)
        other_medication = _check_other(
            "allergies.other_medication",
            value.medication,
            value.other_medication,
        )
        other_food = _check_other(
            "allergies.other_food", value.food, value.other_food
        )
        rows = [
            ("medication", code, other_medication if code == "other" else None)
            for code in _ordered(value.medication, MEDICATION_ALLERGY_CODES)
        ]
        rows += [
            ("food", code, other_food if code == "other" else None)
            for code in _ordered(value.food, FOOD_ALLERGY_CODES)
        ]
        return rows

    # ---- emergency contacts ------------------------------------------

    def _contacts(self, patient: Patient) -> list[EmergencyContact]:
        return list(
            self.session.scalars(
                select(EmergencyContact)
                .where(EmergencyContact.patient_id == patient.id)
                .order_by(EmergencyContact.created_at, EmergencyContact.id)
            )
        )

    def add_contact(
        self,
        actor_id: UUID,
        circle_id: UUID,
        name: str,
        relation: str,
        phone: str,
    ) -> EmergencyContact:
        """Add a contact. At most MAX_EMERGENCY_CONTACTS per patient."""
        name = self._check_contact(name, relation)
        patient = self._open_for(actor_id, circle_id, lock=True)
        contacts = self._contacts(patient)
        if len(contacts) >= MAX_EMERGENCY_CONTACTS:
            raise ValidationFailed(
                f"A patient can have at most {MAX_EMERGENCY_CONTACTS} "
                "emergency contacts.",
                code="too_many_contacts",
            )
        if any(contact.phone_number == phone for contact in contacts):
            raise ValidationFailed(
                "This phone number is already an emergency contact.",
                code="duplicate_contact",
            )
        contact = EmergencyContact(
            patient_id=patient.id,
            name=name,
            relation=relation,
            phone_number=phone,
        )
        self.session.add(contact)
        self.session.flush()
        self.session.refresh(contact)
        return contact

    def update_contact(
        self,
        actor_id: UUID,
        circle_id: UUID,
        contact_id: UUID,
        name: str,
        relation: str,
        phone: str,
    ) -> EmergencyContact:
        """Replace name, relation and phone of one contact."""
        name = self._check_contact(name, relation)
        patient = self._open_for(actor_id, circle_id, lock=True)
        contact = self._get_contact(patient, contact_id)
        if any(
            other.phone_number == phone and other.id != contact.id
            for other in self._contacts(patient)
        ):
            raise ValidationFailed(
                "This phone number is already an emergency contact.",
                code="duplicate_contact",
            )
        contact.name = name
        contact.relation = relation
        contact.phone_number = phone
        self.session.flush()
        return contact

    def delete_contact(
        self, actor_id: UUID, circle_id: UUID, contact_id: UUID
    ) -> None:
        """Remove one contact of this circle's patient."""
        patient = self._open_for(actor_id, circle_id, lock=True)
        self.session.delete(self._get_contact(patient, contact_id))
        self.session.flush()

    def _get_contact(
        self, patient: Patient, contact_id: UUID
    ) -> EmergencyContact:
        """A contact is only reachable through its own patient's circle."""
        contact = self.session.get(
            EmergencyContact,
            contact_id,
            with_for_update=True,
            populate_existing=True,
        )
        if contact is None or contact.patient_id != patient.id:
            raise NotFound("The emergency contact does not exist.")
        return contact

    @staticmethod
    def _check_contact(name: str, relation: str) -> str:
        name = name.strip()
        if not name or len(name) > 50:
            raise _invalid(
                "name", "invalid_name", "The name must be 1 to 50 characters."
            )
        if relation not in CONTACT_RELATIONS:
            raise _invalid("relation", "unknown_choice", "Unknown relation.")
        return name
