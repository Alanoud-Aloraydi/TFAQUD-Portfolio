"""Idempotency record for the scheduled tick's push notifications."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class NotificationLog(db.Model):
    """One row per notification already sent, keyed by a dedupe string.

    The tick runs often and must never resend: it inserts a row here
    before sending, and the unique constraint on `dedupe_key` makes a
    repeat insert fail instead of sending twice.
    """

    __tablename__ = "notification_log"
    __table_args__ = (
        CheckConstraint(
            "length(btrim(dedupe_key)) > 0", name="dedupe_key_nonblank"
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    dedupe_key: Mapped[str] = mapped_column(Text, unique=True)
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
