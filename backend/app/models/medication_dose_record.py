"""Explicit taken or skipped medication occurrences."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, String
from sqlalchemy import Text
from sqlalchemy import UniqueConstraint, text
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
        UniqueConstraint("schedule_id", "scheduled_on"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    schedule_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_schedule.id", ondelete="CASCADE"),
    )
    scheduled_on: Mapped[date] = mapped_column(Date)
    outcome: Mapped[str] = mapped_column(Text)
    taken_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    skip_reason_code: Mapped[str | None] = mapped_column(String(40))
    skip_reason_note: Mapped[str | None] = mapped_column(String(250))
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
