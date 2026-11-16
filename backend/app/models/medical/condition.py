"""The `patient_condition` table."""

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
from app.models.medical.codes import CONDITIONS_SQL, OTHER_TEXT


class PatientCondition(db.Model):
    """One chronic condition of a circle's patient."""

    __tablename__ = "patient_condition"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "code",
            name="uq_patient_condition_care_circle_id_code",
        ),
        CheckConstraint(f"code IN ({CONDITIONS_SQL})", name="code"),
        CheckConstraint(OTHER_TEXT, name="other_text"),
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
