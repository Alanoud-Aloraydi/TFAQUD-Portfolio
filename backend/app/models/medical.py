"""Medical data about the patient, kept in rows beside the patient.

The code lists below are the only values the API accepts. The database checks
the same lists (migration 0005), so a bad value is refused in both places.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Text, text
from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db

BLOOD_TYPES = ("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")
CONDITION_CODES = (
    "diabetes",
    "hypertension",
    "heart",
    "asthma",
    "kidney",
    "thyroid",
    "other",
)
MEDICATION_ALLERGY_CODES = (
    "penicillin",
    "sulfa",
    "cephalosporins",
    "aspirin_nsaids",
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

_CONDITIONS_SQL = ", ".join(f"'{c}'" for c in ("none",) + CONDITION_CODES)
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
    """One chronic condition of a patient. The code 'none' stands alone."""

    __tablename__ = "patient_condition"
    __table_args__ = (
        UniqueConstraint("patient_id", "code"),
        CheckConstraint(f"code IN ({_CONDITIONS_SQL})", name="code"),
        CheckConstraint(_OTHER_TEXT, name="other_text"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"),
    )
    code: Mapped[str] = mapped_column(Text)
    other_text: Mapped[str | None] = mapped_column(Text)


class PatientAllergy(db.Model):
    """One allergy of a patient. kind 'none' means no known allergies."""

    __tablename__ = "patient_allergy"
    __table_args__ = (
        UniqueConstraint("patient_id", "kind", "code"),
        CheckConstraint(
            "(kind = 'none' AND code = 'none') OR "
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
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"),
    )
    kind: Mapped[str] = mapped_column(Text)
    code: Mapped[str] = mapped_column(Text)
    other_text: Mapped[str | None] = mapped_column(Text)


class EmergencyContact(db.Model):
    """A person to call for the patient. One row per phone number."""

    __tablename__ = "emergency_contact"
    __table_args__ = (
        UniqueConstraint("patient_id", "phone_number"),
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
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"),
    )
    name: Mapped[str] = mapped_column(Text)
    relation: Mapped[str] = mapped_column(Text)
    phone_number: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
