"""What the reminders keep: each push the scheduled scan sent
(`notification_log`), so none goes twice, and each task put off with
«ذكّرني لاحقًا» (`task_snooze`)."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Text,
    Time,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


MISSED = ("dose_missed", "measurement_missed", "appointment_missed")

# The reminders at a task's time (app/push/reminders.py).
REMINDERS = (
    "dose_reminder",
    "measurement_reminder",
    "appointment_day_before",
    "appointment_soon",
    "appointment_today",
)

KINDS = MISSED + REMINDERS


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
            "kind IN (" + ", ".join(f"'{kind}'" for kind in KINDS) + ")",
            name="kind",
        ),
        CheckConstraint(
            "(kind IN ('dose_missed', 'appointment_missed')) "
            "= (time_of_day IS NULL)",
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
    # The task's time; null for a missed dose (one per schedule and day)
    # and a missed appointment (one per appointment). A reminder has it, so
    # a task moved to another time is reminded of again.
    time_of_day: Mapped[time | None] = mapped_column(Time)
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), index=True
    )


class TaskSnooze(db.Model):
    """One task put off, the same for everyone in its circle: who put it
    off, for how many minutes, and when it comes again (`remind_at`).

    A task is a dose (`task_id` is its schedule) or a reading time
    (`task_id` is its plan version), on its day at its wall time. Put off
    again, the same row moves: `remind_at` is `minutes` after it was put
    off. `notified_at` is set once the circle was reminded at the new time
    (app/snoozes/due.py).
    """

    __tablename__ = "task_snooze"
    __table_args__ = (
        CheckConstraint("task IN ('dose', 'measurement')", name="task_kind"),
        CheckConstraint("minutes BETWEEN 1 AND 720", name="minutes_range"),
        UniqueConstraint(
            "task", "task_id", "scheduled_on", "time_of_day",
            name="uq_task_snooze_task",
        ),
        # What the scan reads: the snoozes still waiting for their time.
        Index(
            "ix_task_snooze_waiting", "remind_at",
            postgresql_where=text("notified_at IS NULL"),
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    task: Mapped[str] = mapped_column(Text)
    task_id: Mapped[UUID]
    scheduled_on: Mapped[date] = mapped_column(Date)
    time_of_day: Mapped[time] = mapped_column(Time)
    minutes: Mapped[int]
    remind_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    snoozed_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    notified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
