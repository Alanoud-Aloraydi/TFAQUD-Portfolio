"""Medication plans and their immutable versions (`medication_plan`,
`medication_plan_version`), and the dose schedules of each version
(`medication_schedule` with its weekdays and month days)."""

from datetime import date, datetime, time
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    SmallInteger,
    Text,
    Time,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.plan_limits import MISSED_AFTER_CHECK


VERSION_TABLE_ARGS = (
    CheckConstraint("version_number >= 1", name="version_number"),
    CheckConstraint(
        "length(btrim(name)) BETWEEN 1 AND 50", name="name"
    ),
    CheckConstraint(
        "length(btrim(normalized_name)) > 0",
        name="normalized_name_nonblank",
    ),
    CheckConstraint(
        "dosage_form IN "
        "('tablet', 'capsule', 'liquid', 'drops', "
        "'inhaler', 'nebulizer', 'injection')",
        name="dosage_form",
    ),
    CheckConstraint(
        "treatment_ends_on IS NULL "
        "OR treatment_ends_on >= treatment_starts_on",
        name="treatment_dates",
    ),
    CheckConstraint(
        "effective_until_on IS NULL "
        "OR effective_until_on > effective_from_on",
        name="effective_period",
    ),
    CheckConstraint(
        "treatment_ends_on IS NULL "
        "OR treatment_ends_on >= effective_from_on",
        name="effective_treatment",
    ),
    CheckConstraint("strength_value > 0", name="positive_strength"),
    CheckConstraint(
        MISSED_AFTER_CHECK,
        name="missed_after_minutes",
    ),
    CheckConstraint(
        "strength_unit IN ('mg', 'mcg', 'mg/mL', 'mg/5mL', "
        "'mcg/dose', 'unit/mL', '%')",
        name="strength_unit",
    ),
    CheckConstraint(
        "reason_for_use IS NULL OR char_length(reason_for_use) <= 100",
        name="reason_for_use_length",
    ),
    CheckConstraint(
        "instructions IS NULL OR char_length(instructions) <= 250",
        name="instructions_length",
    ),
    UniqueConstraint(
        "medication_plan_id", "version_number",
        name="uq_medication_plan_version_medication_plan_id_"
        "version_number",
    ),
    Index(
        "uq_medication_plan_version_medication_plan_id_effective_from_on",
        "medication_plan_id",
        "effective_from_on",
        unique=True,
        postgresql_where=text("cancelled_at IS NULL"),
    ),
    Index(
        "uq_medication_plan_version_medication_plan_id_open",
        "medication_plan_id",
        unique=True,
        postgresql_where=text(
            "effective_until_on IS NULL AND cancelled_at IS NULL"
        ),
    ),
)


class MedicationPlan(db.Model):
    """Stable medication identity for one circle's patient."""

    __tablename__ = "medication_plan"
    __table_args__ = (
        CheckConstraint(
            "stopped_at IS NOT NULL OR stopped_by_account_id IS NULL",
            name="stopped_state",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    # Null after that account was deleted.
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
    # Null while the medicine is in use.
    stopped_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    # Null while in use, or after that account was deleted.
    stopped_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )


class MedicationPlanVersion(db.Model):
    """One immutable version of medication details and treatment dates."""

    __tablename__ = "medication_plan_version"
    __table_args__ = VERSION_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    medication_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan.id", ondelete="CASCADE"),
    )
    version_number: Mapped[int] = mapped_column(Integer)
    name: Mapped[str] = mapped_column(Text)
    # Derived key of `name` (NFKC, casefold, one space) that the overlap
    # rule compares; kept because SQL cannot reproduce it exactly.
    normalized_name: Mapped[str] = mapped_column(
        Text,
        comment=(
            "Derived key of name (NFKC, casefold, one space) that the overlap "
            "rule compares."
        ),
    )
    strength_value: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    strength_unit: Mapped[str] = mapped_column(Text)
    dosage_form: Mapped[str] = mapped_column(Text)
    reason_for_use: Mapped[str | None] = mapped_column(Text)
    instructions: Mapped[str | None] = mapped_column(Text)
    missed_after_minutes: Mapped[int] = mapped_column(SmallInteger)
    treatment_starts_on: Mapped[date] = mapped_column(Date)
    # Null for a treatment with no end.
    treatment_ends_on: Mapped[date | None] = mapped_column(Date)
    effective_from_on: Mapped[date] = mapped_column(Date)
    # Null for the version in force with no successor.
    effective_until_on: Mapped[date | None] = mapped_column(Date)
    # Null unless an edit replaced this version before it started.
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )


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
    # from the version's treatment_starts_on.
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
