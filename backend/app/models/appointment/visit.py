"""The `appointment_visit` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    LargeBinary,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


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
    # Loaded only when read: a visit is listed without its recording.
    audio: Mapped[bytes | None] = mapped_column(LargeBinary, deferred=True)
    updated_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
