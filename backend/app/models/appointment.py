"""Scheduled care appointments belonging to one patient."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey
from sqlalchemy import LargeBinary, Text, Time
from sqlalchemy import text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class Appointment(db.Model):
    """A single planned visit with an explicit attendance outcome."""

    __tablename__ = "appointment"
    __table_args__ = (
        CheckConstraint(
            "kind IN ('follow_up', 'test', 'imaging', 'remote', 'other')",
            name="kind",
        ),
        CheckConstraint(
            "(kind = 'other' AND other_kind IS NOT NULL AND "
            "length(btrim(other_kind)) > 0 AND "
            "char_length(other_kind) <= 80) OR "
            "(kind <> 'other' AND other_kind IS NULL)",
            name="other_kind_shape",
        ),
        CheckConstraint(
            "status IN ('scheduled', 'completed', 'cancelled')",
            name="status",
        ),
        CheckConstraint(
            "(kind = 'remote' AND remote_method IS NOT NULL "
            "AND remote_method IN ('video', 'phone') "
            "AND place IS NULL) OR (kind <> 'remote' AND "
            "remote_method IS NULL AND place IS NOT NULL AND "
            "length(btrim(place)) > 0)",
            name="location_shape",
        ),
        CheckConstraint(
            "length(btrim(specialty)) > 0 AND "
            "char_length(specialty) <= 80",
            name="specialty",
        ),
        CheckConstraint(
            "place IS NULL OR char_length(place) <= 160",
            name="place_length",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"), index=True
    )
    specialty: Mapped[str] = mapped_column(Text)
    kind: Mapped[str] = mapped_column(Text)
    other_kind: Mapped[str | None] = mapped_column(Text)
    scheduled_on: Mapped[date] = mapped_column(Date)
    time_of_day: Mapped[time] = mapped_column(Time)
    place: Mapped[str | None] = mapped_column(Text)
    remote_method: Mapped[str | None] = mapped_column(Text)
    companion_account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="RESTRICT")
    )
    status: Mapped[str] = mapped_column(Text, default="scheduled")
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )


class AppointmentVisit(db.Model):
    """A completed appointment's written report and optional voice note."""

    __tablename__ = "appointment_visit"
    __table_args__ = (
        CheckConstraint(
            "summary IS NULL OR char_length(summary) <= 2000",
            name="summary_length",
        ),
        CheckConstraint(
            "recommendations IS NULL OR "
            "char_length(recommendations) <= 2000",
            name="recommendations_length",
        ),
        CheckConstraint(
            "follow_up IS NULL OR char_length(follow_up) <= 500",
            name="follow_up_length",
        ),
        CheckConstraint(
            "audio IS NULL OR octet_length(audio) <= 5242880",
            name="audio_size",
        ),
    )

    appointment_id: Mapped[UUID] = mapped_column(
        ForeignKey("appointment.id", ondelete="CASCADE"), primary_key=True
    )
    summary: Mapped[str | None] = mapped_column(Text)
    recommendations: Mapped[str | None] = mapped_column(Text)
    follow_up: Mapped[str | None] = mapped_column(Text)
    audio: Mapped[bytes | None] = mapped_column(LargeBinary)
    updated_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
