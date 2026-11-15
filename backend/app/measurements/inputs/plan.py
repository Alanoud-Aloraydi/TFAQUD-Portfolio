"""The bodies of adding and editing a measurement plan."""

from datetime import date, time
from typing import Annotated

from pydantic import Field, model_validator

from app.measurements.inputs.fields import (
    GLUCOSE_STATES,
    PRESSURE_STATES,
    Kind,
    MeasurementState,
    Value,
)
from app.plan_limits import DEFAULT_MISSED_AFTER_MINUTES, MissedAfter
from app.validation import Dto


class ReadingTime(Dto):
    """One reading time and the planned state of a glucose measurement."""

    time_of_day: time
    measurement_state: MeasurementState | None = None


# Up to six readings a day: fasting, after each meal, at bedtime.
MAX_READING_TIMES = 6


class PlanRequest(Dto):
    """The reading times of a day and the selected weekdays. Fixed normal
    ranges judge the readings (0049): the four target fields are accepted
    from builds before it and ignored."""

    kind: Kind
    times: Annotated[
        list[ReadingTime], Field(min_length=1, max_length=MAX_READING_TIMES)
    ]
    weekdays: Annotated[list[int], Field(min_length=1, max_length=7)]
    starts_on: date
    missed_after_minutes: MissedAfter = DEFAULT_MISSED_AFTER_MINUTES
    glucose_low: Value | None = None
    glucose_high: Value | None = None
    systolic_limit: Value | None = None
    diastolic_limit: Value | None = None

    @property
    def sorted_times(self) -> list[ReadingTime]:
        """The reading times from the earliest of the day."""
        return sorted(self.times, key=lambda item: item.time_of_day)

    @model_validator(mode="after")
    def valid_plan(self):
        """Valid weekdays, and reading times that suit the kind."""
        # Weekdays 1 to 7, each once; reading times without a time zone, each
        # once.
        if len(set(self.weekdays)) != len(self.weekdays) or any(
            day < 1 or day > 7 for day in self.weekdays
        ):
            raise ValueError("Weekdays must be unique and between 1 and 7.")
        moments = [item.time_of_day for item in self.times]
        if any(moment.tzinfo is not None for moment in moments):
            raise ValueError("Reading times have no time zone.")
        if len(set(moments)) != len(moments):
            raise ValueError("Reading times cannot repeat.")
        # A reading time may name no state at all. When it names one, the
        # state belongs to its own kind: the stomach for glucose, the
        # medicine or the morning for pressure.
        allowed = (
            GLUCOSE_STATES if self.kind == "glucose" else PRESSURE_STATES
        )
        for item in self.times:
            state = item.measurement_state
            if state is not None and state not in allowed:
                raise ValueError(
                    "A reading time needs a state of its own kind."
                )
        return self


class RevisePlanRequest(PlanRequest):
    """The body of editing a measurement plan: the same as adding one, plus
    the version it was read from and the day the edit starts (today when
    none)."""

    expected_version_number: Annotated[int, Field(ge=1)]
    effective_from_on: date | None = None
