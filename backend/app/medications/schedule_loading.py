"""Reading the days of many schedules at once."""

from collections import defaultdict
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.medications.schedule_days import ScheduleDays
from app.models import MedicationScheduleDay, MedicationScheduleMonthDay


def load_days(session: Session, schedules) -> dict[UUID, ScheduleDays]:
    """The days of each of `schedules`, read in two queries."""
    # Two reads for all the dose times at once: their weekdays, and their days
    # of the month.
    ids = [schedule.id for schedule in schedules]
    weekdays: dict[UUID, set[int]] = defaultdict(set)
    month_days: dict[UUID, set[int]] = defaultdict(set)
    if ids:
        for schedule_id, weekday in session.execute(
            select(
                MedicationScheduleDay.schedule_id,
                MedicationScheduleDay.weekday,
            ).where(MedicationScheduleDay.schedule_id.in_(ids))
        ):
            weekdays[schedule_id].add(weekday)
        for schedule_id, month_day in session.execute(
            select(
                MedicationScheduleMonthDay.schedule_id,
                MedicationScheduleMonthDay.month_day,
            ).where(MedicationScheduleMonthDay.schedule_id.in_(ids))
        ):
            month_days[schedule_id].add(month_day)
    # Each dose time's days, with its kind of repeat and its interval.
    return {
        schedule.id: ScheduleDays(
            schedule.repeat,
            frozenset(weekdays[schedule.id]),
            frozenset(month_days[schedule.id]),
            schedule.interval_days,
        )
        for schedule in schedules
    }
