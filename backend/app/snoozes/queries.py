"""The snoozes the cards show: who put a task off, and until when."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.models import TaskSnooze


def snooze_response(row: TaskSnooze, accounts: dict) -> dict:
    """What a card shows: the new time, the minutes, and who put it off
    (null once that account is deleted)."""
    return {
        "remind_at": row.remind_at.isoformat(),
        "minutes": row.minutes,
        "snoozed_by": recorder_response(
            accounts.get(row.snoozed_by_account_id)
        ),
    }


def waiting_snoozes(
    session: Session,
    circle_id: UUID,
    task: str,
    start: date,
    end: date,
    now: datetime,
) -> dict[tuple, dict]:
    """The circle's tasks of `task` from `start` to `end` still put off at
    `now`, by (task id, day, wall time), as `snooze_response` gives them."""
    rows = list(
        session.scalars(
            select(TaskSnooze).where(
                TaskSnooze.care_circle_id == circle_id,
                TaskSnooze.task == task,
                TaskSnooze.scheduled_on.between(start, end),
                TaskSnooze.remind_at > now,
            )
        )
    )
    accounts = accounts_by_id(
        session,
        {
            row.snoozed_by_account_id
            for row in rows
            if row.snoozed_by_account_id is not None
        },
    )
    return {
        (str(row.task_id), row.scheduled_on.isoformat(),
         row.time_of_day.strftime("%H:%M")): snooze_response(row, accounts)
        for row in rows
    }


def attach_snoozes(
    session: Session,
    circle_id: UUID,
    task: str,
    occurrences: list[dict],
    start: date,
    end: date,
    now: datetime,
) -> list[dict]:
    """Give each occurrence its `snooze`: null unless it is put off now and
    not yet recorded. A dose is found by its schedule, a reading time by its
    version; both by day and wall time."""
    waiting = waiting_snoozes(session, circle_id, task, start, end, now)
    id_key = "schedule_id" if task == "dose" else "version_id"
    for item in occurrences:
        key = (item[id_key], item["scheduled_on"], item["time_of_day"][:5])
        item["snooze"] = (
            waiting.get(key) if item.get("record") is None else None
        )
    return occurrences


def put_off_until(
    session: Session, circle_id: UUID, task: str, day: date
) -> dict[tuple, datetime]:
    """When each of the circle's tasks of `task` on `day` was last put off
    to, waiting or already come, by (task id, day, wall time): a task put
    off is missed only once its grace has passed after that time."""
    rows = session.scalars(
        select(TaskSnooze).where(
            TaskSnooze.care_circle_id == circle_id,
            TaskSnooze.task == task,
            TaskSnooze.scheduled_on == day,
        )
    )
    return {
        (str(row.task_id), row.scheduled_on.isoformat(),
         row.time_of_day.strftime("%H:%M")): row.remind_at
        for row in rows
    }
