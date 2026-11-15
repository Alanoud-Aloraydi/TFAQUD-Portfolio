"""On which days a medicine schedule applies: weekly, monthly, or every
few days.

A weekly schedule applies on its ISO weekdays (1 Monday .. 7 Sunday). A
monthly one applies on its days of the month, 1 to 28: every month has
them, so a monthly dose is always on the day chosen (migration 0023). An
interval one applies every `interval_days` days from the day its treatment
starts: every 3 days from 1 November is 1, 4, 7 ... (migration 0026).

Should an older row still hold a later day, it lands on the month's last
day when the month lacks it, as the database's own dose rule counts it."""

import calendar
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date

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
