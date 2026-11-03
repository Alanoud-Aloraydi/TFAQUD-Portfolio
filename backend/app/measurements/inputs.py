"""Validated requests for measurement plans and readings."""

from datetime import date, datetime, time
from typing import Annotated, Literal

from pydantic import Field, model_validator

from app.validation import Dto

Kind = Literal["glucose", "bp"]
Context = Literal["fasting", "before_meal", "after_meal", "bedtime", "other"]
Condition = Literal["exertion", "after_meal", "stress", "illness"]
Value = Annotated[int, Field(ge=1, le=999)]


class PlanRequest(Dto):
    """One daily time, selected weekdays, and a user-entered target."""

    kind: Kind
    time_of_day: time
    weekdays: Annotated[list[int], Field(min_length=1, max_length=7)]
    starts_on: date
    grace_minutes: Literal[30, 60, 120] = 60
    glucose_context: Context | None = None
    glucose_low: Value | None = None
    glucose_high: Value | None = None
    systolic_limit: Value | None = None
    diastolic_limit: Value | None = None

    @model_validator(mode="after")
    def valid_plan(self):
        """Require only the targets appropriate to the selected kind."""
        if len(set(self.weekdays)) != len(self.weekdays) or any(
            day < 1 or day > 7 for day in self.weekdays
        ):
            raise ValueError("Weekdays must be unique and between 1 and 7.")
        if self.kind == "glucose":
            if (
                self.glucose_low is None
                or self.glucose_high is None
                or self.glucose_low >= self.glucose_high
                or self.systolic_limit is not None
                or self.diastolic_limit is not None
            ):
                raise ValueError("A glucose target needs a valid range.")
        elif (
            self.systolic_limit is None
            or self.diastolic_limit is None
            or self.systolic_limit <= self.diastolic_limit
            or self.glucose_low is not None
            or self.glucose_high is not None
            or self.glucose_context is not None
        ):
            raise ValueError("Blood pressure needs both upper limits.")
        return self


class RevisePlanRequest(PlanRequest):
    """An optimistic revision effective no earlier than tomorrow."""

    expected_version_number: Annotated[int, Field(ge=1)]
    effective_from_on: date | None = None


class ReadingRequest(Dto):
    """A recorded reading or an explicit skip."""

    kind: Kind
    outcome: Literal["read", "skipped"]
    measured_at: datetime | None = None
    value_one: Value | None = None
    value_two: Value | None = None
    glucose_context: Context | None = None
    condition: Condition | None = None
    note: Annotated[str | None, Field(max_length=250)] = None

    @model_validator(mode="after")
    def valid_values(self):
        """A skip has no reading; a reading has the right number of values."""
        if self.outcome == "skipped":
            if (
                self.measured_at is not None
                or self.value_one is not None
                or self.value_two is not None
            ):
                raise ValueError("A skipped task has no reading.")
        elif (
            self.measured_at is None
            or self.value_one is None
            or (self.kind == "glucose" and self.value_two is not None)
            or (self.kind == "bp" and self.value_two is None)
        ):
            raise ValueError("A reading needs values for its kind.")
        if self.kind == "bp" and self.glucose_context is not None:
            raise ValueError("Blood pressure has no glucose context.")
        if (
            self.outcome == "read" and self.kind == "bp"
            and self.value_one <= self.value_two
        ):
            raise ValueError("Systolic must exceed diastolic.")
        return self


class ReadingQuery(Dto):
    """Bounded range for records and calculated occurrences."""

    from_date: date = Field(alias="from")
    to_date: date = Field(alias="to")

    @model_validator(mode="after")
    def valid_range(self):
        """Prevent oversized or reversed requests."""
        if self.to_date < self.from_date:
            raise ValueError("The end date cannot precede the start.")
        if (self.to_date - self.from_date).days > 31:
            raise ValueError("A request can cover at most 32 days.")
        return self
