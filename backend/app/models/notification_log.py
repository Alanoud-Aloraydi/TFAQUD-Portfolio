"""Idempotency record for the scheduled tick's push notifications."""
from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, Index, Text, Time
from sqlalchemy import text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db

KINDS = ("dose_missed", "measurement_missed")


class NotificationLog(db.Model):
    """One row per notification already sent.

    The tick runs often and must never resend: it inserts a row here before
    sending, and the unique index on (kind, target, day, time) makes a
    repeat insert fail instead of sending twice. Rows older than 14 days
    are purged by the tick (`app.push.scheduled.purge_old_rows`).
    """

    __tablename__ = "notification_log"
    __table_args__ = (
        CheckConstraint(
            "kind IN ('dose_missed', 'measurement_missed', "
            "'appointment_missed')",
            name="kind",
        ),
        CheckConstraint(
            "(kind = 'measurement_missed') = (time_of_day IS NOT NULL)",
            name="time_of_day",
        ),
        Index(
            "uq_notification_log_kind_target_id_scheduled_on_time_of_day",
            "kind", "target_id", "scheduled_on", "time_of_day",
            unique=True,
            postgresql_nulls_not_distinct=True,
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    kind: Mapped[str] = mapped_column(Text)
    # The dose time (`medication_schedule.id`), the reading plan version
    # (`measurement_plan_version.id`) or the appointment; no foreign key, so
    # the log outlives an edited plan until it is purged.
    target_id: Mapped[UUID]
    scheduled_on: Mapped[date] = mapped_column(Date)
    # The reading time; null for a dose (one per schedule and day) and an
    # appointment (one per appointment).
    time_of_day: Mapped[time | None] = mapped_column(Time)
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), index=True
    )
