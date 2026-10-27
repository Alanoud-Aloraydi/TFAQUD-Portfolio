"""Dose schedules belonging to immutable medication-plan versions."""

from datetime import time
from decimal import Decimal
from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, Numeric, SmallInteger
from sqlalchemy import String, Text, Time, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MedicationSchedule(db.Model):
    """Dose amount and local wall-clock time for selected weekdays."""

    __tablename__ = "medication_schedule"
    __table_args__ = (
        CheckConstraint("dose_value > 0", name="positive_dose"),
        CheckConstraint(
            "dose_unit IN "
            "('tablet', 'capsule', 'mL', 'drop', 'puff', 'unit')",
            name="dose_unit",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    plan_version_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan_version.id", ondelete="CASCADE"),
    )
    time_of_day: Mapped[time] = mapped_column(Time)
    dose_value: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    dose_unit: Mapped[str] = mapped_column(Text)
    instructions: Mapped[str | None] = mapped_column(String(250))


class MedicationScheduleDay(db.Model):
    """One ISO weekday on which a medication schedule applies."""

    __tablename__ = "medication_schedule_day"
    __table_args__ = (
        CheckConstraint("weekday BETWEEN 1 AND 7", name="weekday"),
    )

    schedule_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_schedule.id", ondelete="CASCADE"),
        primary_key=True,
    )
    weekday: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
