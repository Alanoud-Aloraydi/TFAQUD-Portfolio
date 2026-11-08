"""On which days a medicine schedule applies: weekly or monthly.

A weekly schedule applies on its ISO weekdays (1 Monday .. 7 Sunday). A
monthly one applies on its days of the month (1 .. 31); a day the month
does not have moves to the month's last day (the 31st is the 30th in
April, and the 29th to the 31st are the 28th or 29th in February), the
same as the app explains under the day picker. A schedule never has two
doses on one day, even when two of its days land on the same last day.
"""

import calendar
from collections import defaultdict
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import MedicationScheduleDay, MedicationScheduleMonthDay

WEEKLY = "weekly"
MONTHLY = "monthly"


@dataclass(frozen=True)
class ScheduleDays:
    """The days of one schedule, as stored."""

    repeat: str
    weekdays: frozenset[int]
    month_days: frozenset[int]

    def applies_on(self, day: date) -> bool:
        return applies_on(self.repeat, self.weekdays, self.month_days, day)


def applies_on(
    repeat: str,
    weekdays: Iterable[int],
    month_days: Iterable[int],
    day: date,
) -> bool:
    """Whether a schedule with these days has a dose on `day`."""
    if repeat == MONTHLY:
        last = calendar.monthrange(day.year, day.month)[1]
        return any(min(month_day, last) == day.day for month_day in month_days)
    return day.isoweekday() in set(weekdays)


def load_days(session: Session, schedules) -> dict[UUID, ScheduleDays]:
    """The days of each of `schedules`, read in two queries."""
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
    return {
        schedule.id: ScheduleDays(
            schedule.repeat,
            frozenset(weekdays[schedule.id]),
            frozenset(month_days[schedule.id]),
        )
        for schedule in schedules
    }
