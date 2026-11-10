"""Putting a task off: the rules, and the one row it keeps."""

from datetime import datetime, time, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound
from app.measurements.queries import MeasurementQueries
from app.medications.queries import MedicationQueries
from app.models import TaskSnooze
from app.snoozes.inputs import SnoozeRequest

# What a reading recorded or skipped says in its status.
_ANSWERED = {"read", "read_late", "skipped"}


class SnoozeService:
    """Puts a dose or a reading time of a circle off, for everyone in it."""

    def __init__(self, session: Session, now: datetime):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def snooze(
        self, circle_id: UUID, actor_id: UUID, body: SnoozeRequest
    ) -> TaskSnooze:
        """Put the task off for `body.minutes` from now: 404 for a task the
        circle does not have that day, 409 `task_already_recorded` once it
        was recorded. Put off again, it moves (the same row)."""
        wall_time = self._unanswered_task(circle_id, body)
        remind_at = self.now + timedelta(minutes=body.minutes)
        values = {
            "care_circle_id": circle_id,
            "minutes": body.minutes,
            "remind_at": remind_at,
            "snoozed_by_account_id": actor_id,
            "snoozed_at": self.now,
            "notified_at": None,
        }
        statement = insert(TaskSnooze).values(
            task=body.task,
            task_id=body.task_id,
            scheduled_on=body.scheduled_on,
            time_of_day=wall_time,
            **values,
        )
        self.session.execute(
            statement.on_conflict_do_update(
                constraint="uq_task_snooze_task", set_=values
            )
        )
        # Read back as saved (the reading above may have loaded the old row).
        return self.session.scalars(
            select(TaskSnooze)
            .where(
                TaskSnooze.task == body.task,
                TaskSnooze.task_id == body.task_id,
                TaskSnooze.scheduled_on == body.scheduled_on,
                TaskSnooze.time_of_day == wall_time,
            )
            .execution_options(populate_existing=True)
        ).one()

    def _unanswered_task(
        self, circle_id: UUID, body: SnoozeRequest
    ) -> time:
        """The wall time of the task `body` names; it must exist that day
        and not be recorded yet."""
        day = body.scheduled_on
        if body.task == "dose":
            found = [
                item
                for item in MedicationQueries(self.session, self.now)
                .occurrences(circle_id, day, day)
                if item["schedule_id"] == str(body.task_id)
            ]
            answered = bool(found) and found[0]["record"] is not None
        else:
            wanted = body.time_of_day.strftime("%H:%M")
            found = [
                item
                for item in MeasurementQueries(self.session, self.now)
                .occurrences(circle_id, day, day)
                if item["version_id"] == str(body.task_id)
                and item["time_of_day"] == wanted
            ]
            answered = bool(found) and found[0]["status"] in _ANSWERED
        if not found:
            raise NotFound("The task does not exist.")
        if answered:
            raise Conflict(code="task_already_recorded")
        return time.fromisoformat(found[0]["time_of_day"])
