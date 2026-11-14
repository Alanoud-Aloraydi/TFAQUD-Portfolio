"""Versioned measurement plans and explicit readings."""
from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index
from sqlalchemy import ForeignKeyConstraint, Integer, SmallInteger, Text
from sqlalchemy import Time, UniqueConstraint, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.plan_limits import MISSED_AFTER_CHECK

KINDS = ("glucose", "blood_pressure")
_KINDS_SQL = "kind IN ('glucose', 'blood_pressure')"

# «ظروف القياس» a reading time or a reading can have (migration 0025), each
# once (0035).
CONDITIONS_CHECK = (
    "conditions <@ ARRAY['fasting', 'before_meal', 'after_meal', 'bedtime', "
    "'before_medicine', 'after_medicine', 'morning', "
    "'exertion', 'stress', 'illness', 'other']::text[]"
)
CONDITIONS_ONCE = (
    "fn_measurement_conditions_unique(conditions)"
)
_TARGET_BY_KIND = (
    "(kind = 'glucose' AND glucose_low IS NOT NULL "
    "AND glucose_high IS NOT NULL AND glucose_low BETWEEN 1 AND 999 "
    "AND glucose_high BETWEEN 1 AND 999 "
    "AND glucose_low < glucose_high AND systolic_limit IS NULL "
    "AND diastolic_limit IS NULL) OR "
    "(kind = 'blood_pressure' AND systolic_limit IS NOT NULL "
    "AND diastolic_limit IS NOT NULL "
    "AND systolic_limit BETWEEN 1 AND 999 "
    "AND diastolic_limit BETWEEN 1 AND 999 "
    "AND systolic_limit > diastolic_limit AND glucose_low IS NULL "
    "AND glucose_high IS NULL)"
)


class MeasurementPlan(db.Model):
    """A patient's glucose or blood-pressure monitoring plan."""

    __tablename__ = "measurement_plan"
    __table_args__ = (
        CheckConstraint(_KINDS_SQL, name="kind"),
        CheckConstraint(
            "stopped_at IS NOT NULL OR stopped_by_account_id IS NULL",
            name="stopped_state",
        ),
        Index(
            "uq_measurement_plan_care_circle_id_kind_active",
            "care_circle_id", "kind", unique=True,
            postgresql_where=text("stopped_at IS NULL"),
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(Text)
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    # Null while the plan is in use.
    stopped_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    # Null while in use, or after that account was deleted.
    stopped_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )


class MeasurementTarget(db.Model):
    """The target once saved for one patient and measurement kind, for
    readings without a plan. Fixed ranges replaced it (0049): it is kept
    with its data and no longer read or written."""

    __tablename__ = "measurement_target"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "kind",
            name="uq_measurement_target_care_circle_id_kind",
        ),
        CheckConstraint(_KINDS_SQL, name="kind"),
        CheckConstraint(_TARGET_BY_KIND, name="target_shape"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE")
    )
    kind: Mapped[str] = mapped_column(Text)
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)


class MeasurementPlanVersion(db.Model):
    """A plan's days and grace over an immutable date range; its
    reading times are `MeasurementPlanTime` rows and its weekdays
    `MeasurementPlanWeekday` rows."""

    __tablename__ = "measurement_plan_version"
    __table_args__ = (
        UniqueConstraint(
            "measurement_plan_id", "version_number",
            name="uq_measurement_plan_version_measurement_plan_id_"
            "version_number",
        ),
        UniqueConstraint(
            "measurement_plan_id", "effective_from_on",
            name="uq_measurement_plan_version_measurement_plan_"
            "effective_from_on",
        ),
        CheckConstraint("version_number > 0", name="version_number"),
        CheckConstraint(
            MISSED_AFTER_CHECK,
            name="missed_after_minutes",
        ),
        CheckConstraint(
            "effective_until_on IS NULL OR "
            "effective_until_on > effective_from_on",
            name="effective_period",
        ),
        # None since fixed ranges judge readings (0049), or an old target.
        CheckConstraint(
            "(glucose_low IS NULL AND glucose_high IS NULL "
            "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
            "AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 "
            "AND glucose_high > glucose_low "
            "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(glucose_low IS NULL AND glucose_high IS NULL "
            "AND systolic_limit BETWEEN 1 AND 999 "
            "AND diastolic_limit BETWEEN 1 AND 999 "
            "AND systolic_limit > diastolic_limit)",
            name="target_shape",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    measurement_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey(
            "measurement_plan.id", ondelete="CASCADE",
            name="fk_measurement_plan_version_measurement_plan_id",
        )
    )
    version_number: Mapped[int] = mapped_column(Integer)
    effective_from_on: Mapped[date] = mapped_column(Date)
    # Null for the version in force with no successor.
    effective_until_on: Mapped[date | None] = mapped_column(Date)
    missed_after_minutes: Mapped[int] = mapped_column(SmallInteger)
    # The target this version judged readings by, before fixed ranges
    # (0049); none for a newer version.
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )


class MeasurementPlanWeekday(db.Model):
    """One ISO weekday (1 Monday .. 7 Sunday) of a plan version."""

    __tablename__ = "measurement_plan_weekday"
    __table_args__ = (
        CheckConstraint("weekday BETWEEN 1 AND 7", name="weekday"),
    )

    plan_version_id: Mapped[UUID] = mapped_column(
        ForeignKey(
            "measurement_plan_version.id", ondelete="CASCADE",
            name="fk_measurement_plan_weekday_plan_version_id",
        ),
        primary_key=True,
    )
    weekday: Mapped[int] = mapped_column(SmallInteger, primary_key=True)


class MeasurementPlanTime(db.Model):
    """One reading time of a plan version and its glucose measurement state."""

    __tablename__ = "measurement_plan_time"
    __table_args__ = (
        CheckConstraint(
            "measurement_state IS NULL OR measurement_state IN "
            "('fasting', 'before_meal', 'after_meal', "
            "'before_medicine', 'after_medicine', 'morning')",
            name="measurement_state",
        ),
    )

    plan_version_id: Mapped[UUID] = mapped_column(
        ForeignKey(
            "measurement_plan_version.id", ondelete="CASCADE",
            name="fk_measurement_plan_time_plan_version_id",
        ),
        primary_key=True,
    )
    time_of_day: Mapped[time] = mapped_column(Time, primary_key=True)
    measurement_state: Mapped[str | None] = mapped_column(Text)


class MeasurementReading(db.Model):
    """A reading or an explicit skip of a plan's reading time, or a reading
    taken outside a plan."""

    __tablename__ = "measurement_reading"
    __table_args__ = (
        # One outcome per reading time of a day.
        UniqueConstraint(
            "plan_version_id", "scheduled_on", "scheduled_time",
            name="uq_measurement_reading_plan_version_scheduled_on_"
            "scheduled_time",
        ),
        # A task's reading names one of its version's reading times.
        ForeignKeyConstraint(
            ["plan_version_id", "scheduled_time"],
            [
                "measurement_plan_time.plan_version_id",
                "measurement_plan_time.time_of_day",
            ],
            ondelete="CASCADE",
            name="fk_measurement_reading_plan_version_id_"
            "measurement_plan_time",
        ),
        CheckConstraint(_KINDS_SQL, name="kind"),
        CheckConstraint("outcome IN ('read', 'skipped')", name="outcome"),
        CheckConstraint(CONDITIONS_CHECK, name="conditions"),
        CheckConstraint(CONDITIONS_ONCE, name="conditions_once"),
        CheckConstraint(
            "outcome = 'read' OR plan_version_id IS NOT NULL",
            name="skip_linked",
        ),
        CheckConstraint(
            "note IS NULL OR char_length(note) <= 250",
            name="note_length",
        ),
        CheckConstraint(
            "skip_reason_code IS NULL OR skip_reason_code IN "
            "('forgotten', 'equipment_unavailable', 'patient_refused', "
            "'unwell', 'other')",
            name="skip_reason",
        ),
        CheckConstraint(
            "skip_reason_note IS NULL OR "
            "(skip_reason_code = 'other' AND "
            "char_length(skip_reason_note) BETWEEN 1 AND 250)",
            name="skip_reason_note",
        ),
        CheckConstraint(
            "(outcome = 'read' AND skip_reason_code IS NULL AND "
            "skip_reason_note IS NULL) OR outcome = 'skipped'",
            name="skip_reason_outcome",
        ),
        # The words of «أخرى», only with it (migration 0028).
        CheckConstraint(
            "other_text IS NULL OR (char_length(other_text) "
            "BETWEEN 1 AND 60 AND 'other' = ANY(conditions))",
            name="other_text",
        ),
        CheckConstraint(
            "(plan_version_id IS NULL AND scheduled_on IS NULL "
            "AND scheduled_time IS NULL) OR "
            "(plan_version_id IS NOT NULL AND scheduled_on IS NOT NULL "
            "AND scheduled_time IS NOT NULL)",
            name="schedule_pair",
        ),
        CheckConstraint(
            "(outcome = 'skipped' AND measured_at IS NULL AND "
            "glucose_value IS NULL AND systolic_value IS NULL AND "
            "diastolic_value IS NULL AND followed_up_at IS NULL) OR "
            "(outcome = 'read' AND measured_at IS NOT NULL AND "
            "((kind = 'glucose' AND glucose_value BETWEEN 1 AND 999 "
            "AND systolic_value IS NULL AND diastolic_value IS NULL) OR "
            "(kind = 'blood_pressure' AND glucose_value IS NULL "
            "AND systolic_value BETWEEN 1 AND 999 "
            "AND diastolic_value BETWEEN 1 AND 999 "
            "AND systolic_value > diastolic_value)))",
            name="value_shape",
        ),
        CheckConstraint(
            "(glucose_low IS NULL AND glucose_high IS NULL AND "
            "systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(plan_version_id IS NULL AND outcome = 'read' AND ("
            + _TARGET_BY_KIND + "))",
            name="free_target_shape",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    # Null for a reading taken outside a plan.
    plan_version_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("measurement_plan_version.id", ondelete="CASCADE")
    )
    scheduled_on: Mapped[date | None] = mapped_column(Date)
    # Which reading time of that day; null for a reading outside a plan.
    scheduled_time: Mapped[time | None] = mapped_column(Time)
    kind: Mapped[str] = mapped_column(Text)
    outcome: Mapped[str] = mapped_column(Text)
    # Null for a skip.
    measured_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    glucose_value: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_value: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_value: Mapped[int | None] = mapped_column(SmallInteger)
    conditions: Mapped[list[str]] = mapped_column(
        ARRAY(Text), server_default=text("'{}'"), default=list
    )
    # What «أخرى» was, in the reader's words: «بعد القهوة».
    other_text: Mapped[str | None] = mapped_column(Text)
    note: Mapped[str | None] = mapped_column(Text)
    skip_reason_code: Mapped[str | None] = mapped_column(Text)
    skip_reason_note: Mapped[str | None] = mapped_column(Text)
    # The target a reading outside a plan was judged by, before fixed
    # ranges (0049); none for a newer reading.
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    followed_up_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
