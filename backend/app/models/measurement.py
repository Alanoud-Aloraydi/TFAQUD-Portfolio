"""Versioned measurement schedules and explicit readings."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index
from sqlalchemy import (
    Integer,
    SmallInteger,
    Text,
    Time,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MeasurementPlan(db.Model):
    """A patient's glucose or blood-pressure monitoring plan."""

    __tablename__ = "measurement_plan"
    __table_args__ = (
        CheckConstraint("kind IN ('glucose', 'bp')", name="kind"),
        Index(
            "uq_measurement_plan_active_kind",
            "patient_id", "kind", unique=True,
            postgresql_where=text("stopped_at IS NULL"),
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(Text)
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    stopped_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )


class MeasurementTarget(db.Model):
    """The saved standalone target for one patient and measurement kind."""

    __tablename__ = "measurement_target"
    __table_args__ = (
        UniqueConstraint("patient_id", "kind"),
        CheckConstraint("kind IN ('glucose', 'bp')", name="kind"),
        CheckConstraint(
            "(kind = 'glucose' AND glucose_low IS NOT NULL "
            "AND glucose_high IS NOT NULL AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 "
            "AND glucose_low < glucose_high AND systolic_limit IS NULL "
            "AND diastolic_limit IS NULL) OR "
            "(kind = 'bp' AND systolic_limit IS NOT NULL "
            "AND diastolic_limit IS NOT NULL "
            "AND systolic_limit BETWEEN 1 AND 999 "
            "AND diastolic_limit BETWEEN 1 AND 999 "
            "AND systolic_limit > diastolic_limit AND glucose_low IS NULL "
            "AND glucose_high IS NULL)",
            name="target_shape",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE")
    )
    kind: Mapped[str] = mapped_column(Text)
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)


class MeasurementPlanVersion(db.Model):
    """A schedule and target valid over an immutable date range."""

    __tablename__ = "measurement_plan_version"
    __table_args__ = (
        UniqueConstraint("plan_id", "number"),
        UniqueConstraint(
            "plan_id",
            "effective_from_on",
            name="uq_measurement_plan_version_effective_from_on",
        ),
        CheckConstraint("number > 0", name="number"),
        CheckConstraint("weekdays_mask BETWEEN 1 AND 127", name="weekdays"),
        CheckConstraint(
            "grace_minutes IN (30, 60, 120)", name="grace_minutes"
        ),
        CheckConstraint(
            "effective_until_on IS NULL OR "
            "effective_until_on > effective_from_on",
            name="effective_period",
        ),
        CheckConstraint(
            "(glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
            "AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 "
            "AND glucose_high > glucose_low "
            "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(glucose_low IS NULL AND glucose_high IS NULL "
            "AND glucose_context IS NULL "
            "AND systolic_limit BETWEEN 1 AND 999 "
            "AND diastolic_limit BETWEEN 1 AND 999 "
            "AND systolic_limit > diastolic_limit)",
            name="target_shape",
        ),
        CheckConstraint(
            "glucose_context IS NULL OR glucose_context IN "
            "('fasting', 'before_meal', 'after_meal', 'bedtime', 'other')",
            name="glucose_context",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    plan_id: Mapped[UUID] = mapped_column(
        ForeignKey("measurement_plan.id", ondelete="CASCADE")
    )
    number: Mapped[int] = mapped_column(Integer)
    effective_from_on: Mapped[date] = mapped_column(Date)
    effective_until_on: Mapped[date | None] = mapped_column(Date)
    time_of_day: Mapped[time] = mapped_column(Time)
    weekdays_mask: Mapped[int] = mapped_column(SmallInteger)
    grace_minutes: Mapped[int] = mapped_column(SmallInteger)
    glucose_context: Mapped[str | None] = mapped_column(Text)
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )


class MeasurementRecord(db.Model):
    """A measured or skipped occurrence, or a standalone reading."""

    __tablename__ = "measurement_record"
    __table_args__ = (
        UniqueConstraint("plan_version_id", "scheduled_on"),
        CheckConstraint("kind IN ('glucose', 'bp')", name="kind"),
        CheckConstraint("outcome IN ('read', 'skipped')", name="outcome"),
        CheckConstraint(
            "glucose_context IS NULL OR glucose_context IN "
            "('fasting', 'before_meal', 'after_meal', 'bedtime', 'other')",
            name="glucose_context",
        ),
        CheckConstraint(
            "condition IS NULL OR condition IN "
            "('exertion', 'after_meal', 'stress', 'illness')",
            name="condition",
        ),
        CheckConstraint(
            "kind = 'glucose' OR glucose_context IS NULL",
            name="context_kind",
        ),
        CheckConstraint(
            "outcome = 'read' OR plan_version_id IS NOT NULL",
            name="skip_linked",
        ),
        CheckConstraint(
            "note IS NULL OR char_length(note) <= 250",
            name="note_length",
        ),
        CheckConstraint(
            "(plan_version_id IS NULL AND scheduled_on IS NULL) OR "
            "(plan_version_id IS NOT NULL AND scheduled_on IS NOT NULL)",
            name="schedule_pair",
        ),
        CheckConstraint(
            "(outcome = 'skipped' AND measured_at IS NULL AND "
            "value_one IS NULL AND value_two IS NULL AND "
            "followed_up_at IS NULL) OR "
            "(outcome = 'read' AND measured_at IS NOT NULL AND "
            "value_one BETWEEN 1 AND 999 AND "
            "((kind = 'glucose' AND value_two IS NULL) OR "
            "(kind = 'bp' AND value_two BETWEEN 1 AND 999 "
            "AND value_one > value_two)))",
            name="value_shape",
        ),
        CheckConstraint(
            "(glucose_low IS NULL AND glucose_high IS NULL AND "
            "systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(plan_version_id IS NULL AND outcome = 'read' AND "
            "((kind = 'glucose' AND glucose_low IS NOT NULL AND "
            "glucose_high IS NOT NULL AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 AND "
            "glucose_low < glucose_high AND systolic_limit IS NULL AND "
            "diastolic_limit IS NULL) OR "
            "(kind = 'bp' AND systolic_limit IS NOT NULL AND "
            "diastolic_limit IS NOT NULL AND "
            "systolic_limit BETWEEN 1 AND 999 AND "
            "diastolic_limit BETWEEN 1 AND 999 AND "
            "systolic_limit > diastolic_limit AND glucose_low IS NULL "
            "AND glucose_high IS NULL)))",
            name="free_target_shape",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"), index=True
    )
    plan_version_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("measurement_plan_version.id", ondelete="CASCADE")
    )
    scheduled_on: Mapped[date | None] = mapped_column(Date)
    kind: Mapped[str] = mapped_column(Text)
    outcome: Mapped[str] = mapped_column(Text)
    measured_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    value_one: Mapped[int | None] = mapped_column(SmallInteger)
    value_two: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_context: Mapped[str | None] = mapped_column(Text)
    condition: Mapped[str | None] = mapped_column(Text)
    note: Mapped[str | None] = mapped_column(Text)
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    followed_up_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
