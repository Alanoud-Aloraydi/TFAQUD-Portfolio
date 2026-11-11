"""Dose schedules belonging to immutable medication-plan versions."""

from datetime import time
from decimal import Decimal
from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, Numeric, SmallInteger
from sqlalchemy import Text, Time, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MedicationSchedule(db.Model):
    """Dose amount and local wall-clock time, repeated weekly on selected
    weekdays, monthly on selected days of the month, or every few days from
    the treatment's start."""

    __tablename__ = "medication_schedule"
    __table_args__ = (
        CheckConstraint("dose_value > 0", name="positive_dose"),
        CheckConstraint(
            "dose_unit IN "
            "('tablet', 'capsule', 'mL', 'drop', 'puff', 'unit')",
            name="dose_unit",
        ),
        CheckConstraint(
            "repeat IN ('weekly', 'monthly', 'interval')",
            name="repeat",
        ),
        CheckConstraint(
            "(repeat = 'interval' AND interval_days IS NOT NULL "
            "AND interval_days BETWEEN 1 AND 90) OR "
            "(repeat <> 'interval' AND interval_days IS NULL)",
            name="interval_days",
        ),
        CheckConstraint(
            "instructions IS NULL OR char_length(instructions) <= 250",
            name="instructions_length",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    plan_version_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan_version.id", ondelete="CASCADE"),
        index=True,
    )
    time_of_day: Mapped[time] = mapped_column(Time)
    dose_value: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    dose_unit: Mapped[str] = mapped_column(Text)
    instructions: Mapped[str | None] = mapped_column(Text)
    # Weekly: the days are in medication_schedule_day. Monthly: they are in
    # medication_schedule_month_day. Interval: every `interval_days` days
    # from the version's treatment_starts_on (migration 0026).
    repeat: Mapped[str] = mapped_column(
        Text, server_default=text("'weekly'")
    )
    interval_days: Mapped[int | None] = mapped_column(SmallInteger)


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


class MedicationScheduleMonthDay(db.Model):
    """One day of the month (1 to 28, the days every month has) on which a
    monthly schedule applies."""

    __tablename__ = "medication_schedule_month_day"
    __table_args__ = (
        CheckConstraint("month_day BETWEEN 1 AND 28", name="month_day"),
    )

    schedule_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_schedule.id", ondelete="CASCADE"),
        primary_key=True,
    )
    month_day: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
