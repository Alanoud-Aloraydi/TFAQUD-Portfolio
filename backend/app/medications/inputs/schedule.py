"""One dose time of a medicine and how it repeats."""

from datetime import time
from typing import Annotated, Literal

from pydantic import Field, field_validator, model_validator

from app.medications.inputs.fields import (
    MAX_INTERVAL_DAYS,
    DoseUnit,
    DoseValue,
    OptionalText250,
    english_decimal,
)
from app.validation import Dto


class ScheduleRequest(Dto):
    """One dose time: weekly on `weekdays` (ISO, 1 Monday .. 7 Sunday),
    monthly on `month_days` (1 .. 28, the days every month has), or every
    `interval_days` days from the treatment's start. An older app sends
    only `weekdays`, which is weekly."""

    time_of_day: time
    dose_value: DoseValue
    dose_unit: DoseUnit
    repeat: Literal["weekly", "monthly", "interval"] = "weekly"
    weekdays: Annotated[list[int], Field(max_length=7)] = []
    month_days: Annotated[list[int], Field(max_length=28)] = []
    interval_days: Annotated[
        int | None, Field(ge=1, le=MAX_INTERVAL_DAYS)
    ] = None
    instructions: OptionalText250 = None

    @field_validator("dose_value", mode="before")
    @classmethod
    def valid_dose_number(cls, value):
        """Accept the dose only in English digits, with a zero before the
        decimal point (0.5, not .5).
        """
        return english_decimal(value)

    @model_validator(mode="after")
    def valid_days(self):
        """Each kind of repeat has its own days: weekdays for weekly, days of
        the month for monthly, a number of days for interval.
        """
        if (self.repeat == "interval") != (self.interval_days is not None):
            raise ValueError("Only an interval dose has interval days.")
        # Every few days: only its number of days.
        if self.repeat == "interval":
            if self.weekdays or self.month_days:
                raise ValueError("An interval dose has no other days.")
        # Weekly: one weekday at least, 1 to 7, each once, and no days of the
        # month.
        elif self.repeat == "weekly":
            if not self.weekdays:
                raise ValueError("Choose at least one weekday.")
            if self.month_days:
                raise ValueError("A weekly dose has no days of the month.")
            if len(set(self.weekdays)) != len(self.weekdays):
                raise ValueError("Weekdays cannot repeat.")
            if any(day < 1 or day > 7 for day in self.weekdays):
                raise ValueError("Weekdays must be between 1 and 7.")
        # Monthly: one day of the month at least, 1 to 28 (every month has
        # them), each once, and no weekdays.
        else:
            if not self.month_days:
                raise ValueError("Choose at least one day of the month.")
            if self.weekdays:
                raise ValueError("A monthly dose has no weekdays.")
            if len(set(self.month_days)) != len(self.month_days):
                raise ValueError("Days of the month cannot repeat.")
            if any(day < 1 or day > 28 for day in self.month_days):
                raise ValueError("Days of the month must be 1 to 28.")
        return self
