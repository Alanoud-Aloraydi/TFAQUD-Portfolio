"""On which days a medicine schedule applies, read for many schedules at
once, and whether a version is in force on a day and how late a dose is.

A weekly schedule applies on its ISO weekdays (1 Monday .. 7 Sunday), a
monthly one on its days of the month, and an interval one every few days
from its start."""

import calendar
from collections import defaultdict
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import MedicationScheduleDay, MedicationScheduleMonthDay


WEEKLY = "weekly"

MONTHLY = "monthly"

INTERVAL = "interval"


@dataclass(frozen=True)
class ScheduleDays:
    """The days of one schedule, as stored."""

    repeat: str
    weekdays: frozenset[int]
    month_days: frozenset[int]
    interval_days: int | None = None

    def applies_on(self, day: date, treatment_starts_on: date) -> bool:
        """Whether this dose time has a dose on `day`, by its kind of repeat.
        """
        return applies_on(
            self.repeat,
            self.weekdays,
            self.month_days,
            day,
            interval_days=self.interval_days,
            treatment_starts_on=treatment_starts_on,
        )


def applies_on(
    repeat: str,
    weekdays: Iterable[int],
    month_days: Iterable[int],
    day: date,
    interval_days: int | None = None,
    treatment_starts_on: date | None = None,
) -> bool:
    """Whether a schedule with these days has a dose on `day`."""
    if repeat == INTERVAL:
        if not interval_days or treatment_starts_on is None:
            return False
        since = (day - treatment_starts_on).days
        return since >= 0 and since % interval_days == 0
    if repeat == MONTHLY:
        last = calendar.monthrange(day.year, day.month)[1]
        return any(min(month_day, last) == day.day for month_day in month_days)
    if repeat == WEEKLY:
        return day.isoweekday() in set(weekdays)
    # The database allows only the three above; anything else is a bug.
    raise ValueError(f"Unknown schedule repeat {repeat!r}.")


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


def version_applies(version, day: date) -> bool:
    """Whether the medicine version is in force on `day`: inside its treatment
    dates and its own start and end.
    """
    if version.treatment_starts_on > day:
        return False
    if version.treatment_ends_on is not None:
        if version.treatment_ends_on < day:
            return False
    if version.effective_from_on > day:
        return False
    if version.effective_until_on is not None:
        if version.effective_until_on <= day:
            return False
    return True


def timing_state(scheduled_at, now, record, missed_after_minutes):
    """Return timing without persisting calculated occurrences.

    `scheduled_at` and `now` are instants (`local_moment` gives UTC), so the
    minutes are real minutes even across a DST change."""
    if record is not None:
        return None
    if now < scheduled_at:
        return "upcoming"
    if now < scheduled_at + timedelta(minutes=15):
        return "due"
    if now < scheduled_at + timedelta(minutes=missed_after_minutes):
        return "late"
    return "missed"
