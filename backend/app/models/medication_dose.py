"""What was done with the doses: each dose time taken or skipped
(`medication_dose_record`), and doses taken outside the dose times
(`medication_extra_dose`, «سجّل جرعة الآن»)."""

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MedicationDoseRecord(db.Model):
    """One explicit outcome for a scheduled dose on a calendar date."""

    __tablename__ = "medication_dose_record"
    __table_args__ = (
        CheckConstraint(
            "outcome IN ('taken', 'skipped')", name="outcome"
        ),
        CheckConstraint(
            "(outcome = 'taken' AND taken_at IS NOT NULL "
            "AND skip_reason_code IS NULL AND skip_reason_note IS NULL) "
            "OR (outcome = 'skipped' AND taken_at IS NULL)",
            name="outcome_details",
        ),
        CheckConstraint(
            "taken_at IS NULL OR taken_at <= recorded_at",
            name="taken_before_recorded",
        ),
        CheckConstraint(
            "skip_reason_code IS NULL OR skip_reason_code IN "
            "('forgotten', 'unavailable', 'side_effects', "
            "'patient_refused', 'other')",
            name="skip_reason",
        ),
        CheckConstraint(
            "skip_reason_note IS NULL OR skip_reason_code = 'other'",
            name="skip_note",
        ),
        CheckConstraint(
            "skip_reason_note IS NULL OR char_length(skip_reason_note) <= 250",
            name="skip_reason_note_length",
        ),
        UniqueConstraint(
            "schedule_id", "scheduled_on",
            name="uq_medication_dose_record_schedule_id_scheduled_on",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    schedule_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_schedule.id", ondelete="CASCADE"),
    )
    # Indexed for the tick that deletes the days past three months.
    scheduled_on: Mapped[date] = mapped_column(Date, index=True)
    outcome: Mapped[str] = mapped_column(Text)
    taken_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    skip_reason_code: Mapped[str | None] = mapped_column(Text)
    skip_reason_note: Mapped[str | None] = mapped_column(Text)
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )


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
