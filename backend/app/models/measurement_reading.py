"""The `measurement_reading` table: one reading taken or skipped, from a
plan's reading time or on its own."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    SmallInteger,
    Text,
    Time,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.measurement import (
    CONDITIONS_CHECK,
    CONDITIONS_ONCE,
    KINDS_SQL,
)


READING_TABLE_ARGS = (
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
    CheckConstraint(KINDS_SQL, name="kind"),
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
    # The words of «أخرى», only with it.
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
)


class MeasurementReading(db.Model):
    """A reading or an explicit skip of a plan's reading time, or a reading
    taken outside a plan."""

    __tablename__ = "measurement_reading"
    __table_args__ = READING_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    plan_version_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("measurement_plan_version.id", ondelete="CASCADE"),
        comment="Null for a reading taken outside a plan.",
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
    followed_up_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
