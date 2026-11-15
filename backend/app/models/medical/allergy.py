"""The `patient_allergy` table."""

from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    ForeignKey,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.medical.codes import FOOD_SQL, MEDICATION_SQL, OTHER_TEXT


class PatientAllergy(db.Model):
    """One allergy of a circle's patient: a medication or a food."""

    __tablename__ = "patient_allergy"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "kind", "code",
            name="uq_patient_allergy_care_circle_id_kind_code",
        ),
        CheckConstraint(
            f"(kind = 'medication' AND code IN ({MEDICATION_SQL})) OR "
            f"(kind = 'food' AND code IN ({FOOD_SQL}))",
            name="kind_code",
        ),
        CheckConstraint(OTHER_TEXT, name="other_text"),
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
