"""Doses taken outside the dose times: «سجّل جرعة الآن»."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Numeric, Text
from sqlalchemy import text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MedicationExtraDose(db.Model):
    """One dose of a medicine taken when the person chose, always on top of
    its scheduled doses, which it never answers."""

    __tablename__ = "medication_extra_dose"
    __table_args__ = (
        CheckConstraint("dose_value > 0", name="positive_dose"),
        CheckConstraint(
            "dose_unit IN "
            "('tablet', 'capsule', 'mL', 'drop', 'puff', 'unit')",
            name="dose_unit",
        ),
        CheckConstraint(
            "taken_at <= recorded_at", name="taken_before_recorded"
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    medication_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan.id", ondelete="CASCADE"),
        index=True,
    )
    taken_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), index=True
    )
    dose_value: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    dose_unit: Mapped[str] = mapped_column(Text)
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
