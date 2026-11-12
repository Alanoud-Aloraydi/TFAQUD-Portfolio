"""A dose or a reading time put off with «ذكّرني لاحقًا», for the circle."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Text
from sqlalchemy import Time, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class TaskSnooze(db.Model):
    """One task put off, the same for everyone in its circle: who put it
    off, for how many minutes, and when it comes again (`remind_at`).

    A task is a dose (`task_id` is its schedule) or a reading time
    (`task_id` is its plan version), on its day at its wall time. Put off
    again, the same row moves. `notified_at` is set once the circle was
    reminded at the new time (app/snoozes/due.py).
    """

    __tablename__ = "task_snooze"
    __table_args__ = (
        CheckConstraint("task IN ('dose', 'measurement')", name="task_kind"),
        CheckConstraint("minutes BETWEEN 1 AND 720", name="minutes_range"),
        CheckConstraint("remind_at > snoozed_at", name="remind_order"),
        UniqueConstraint(
            "task", "task_id", "scheduled_on", "time_of_day",
            name="uq_task_snooze_task",
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
    snoozed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    notified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
