"""The medical file of a circle's patient: conditions, allergies, contacts.

The code lists below are the only values the API accepts, and the database
checks the same lists. Whether the patient has none of them is not a row:
it is `care_circle.conditions_status` / `allergies_status` (migration 0038).
"""
from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Text, text
from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.circle import BLOOD_TYPES

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

# Ordered as the app shows them: the most common first.
CONDITION_CODES = (
    "diabetes",
    "hypertension",
    "cholesterol",
    "heart",
    "stroke",
    "asthma",
    "kidney",
    "thyroid",
    "arthritis",
    "osteoporosis",
    "dementia",
    "depression_anxiety",
    "cancer",
    "other",
)
MEDICATION_ALLERGY_CODES = (
    "penicillin",
    "sulfa",
    "cephalosporins",
    "quinolones",
    "aspirin",
    "nsaids",
    "opioids",
    "contrast_media",
    "anesthesia",
    "other",
)
FOOD_ALLERGY_CODES = (
    "milk",
    "eggs",
    "fish",
    "shellfish",
    "tree_nuts",
    "peanuts",
    "wheat",
    "soy",
    "sesame",
    "other",
)
CONTACT_RELATIONS = ("son", "daughter", "husband", "wife", "other")

_CONDITIONS_SQL = ", ".join(f"'{c}'" for c in CONDITION_CODES)
_MEDICATION_SQL = ", ".join(f"'{c}'" for c in MEDICATION_ALLERGY_CODES)
_FOOD_SQL = ", ".join(f"'{c}'" for c in FOOD_ALLERGY_CODES)
_RELATIONS_SQL = ", ".join(f"'{c}'" for c in CONTACT_RELATIONS)

# "other" always carries the text the user typed; every other code has none.
_OTHER_TEXT = (
    "(code = 'other' AND other_text IS NOT NULL "
    "AND length(btrim(other_text)) BETWEEN 1 AND 100) OR "
    "(code <> 'other' AND other_text IS NULL)"
)


class PatientCondition(db.Model):
    """One chronic condition of a circle's patient."""

    __tablename__ = "patient_condition"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "code",
            name="uq_patient_condition_care_circle_id_code",
        ),
        CheckConstraint(f"code IN ({_CONDITIONS_SQL})", name="code"),
        CheckConstraint(_OTHER_TEXT, name="other_text"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
    )
    code: Mapped[str] = mapped_column(Text)
    # The words of «أخرى»; null for every other code.
    other_text: Mapped[str | None] = mapped_column(Text)


class PatientAllergy(db.Model):
    """One allergy of a circle's patient: a medication or a food."""

    __tablename__ = "patient_allergy"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "kind", "code",
            name="uq_patient_allergy_care_circle_id_kind_code",
        ),
        CheckConstraint(
            f"(kind = 'medication' AND code IN ({_MEDICATION_SQL})) OR "
            f"(kind = 'food' AND code IN ({_FOOD_SQL}))",
            name="kind_code",
        ),
        CheckConstraint(_OTHER_TEXT, name="other_text"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
    )
    kind: Mapped[str] = mapped_column(Text)
    code: Mapped[str] = mapped_column(Text)
    # The words of «أخرى»; null for every other code.
    other_text: Mapped[str | None] = mapped_column(Text)


class EmergencyContact(db.Model):
    """A person to call for the patient. One row per phone number."""

    __tablename__ = "emergency_contact"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "phone_number",
            name="uq_emergency_contact_care_circle_id_phone_number",
        ),
        CheckConstraint("length(btrim(name)) BETWEEN 1 AND 50", name="name"),
        CheckConstraint(f"relation IN ({_RELATIONS_SQL})", name="relation"),
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
    )
    name: Mapped[str] = mapped_column(Text)
    relation: Mapped[str] = mapped_column(Text)
    phone_number: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
