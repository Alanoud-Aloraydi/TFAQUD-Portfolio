"""Validated requests for measurement plans and readings."""

from datetime import date, datetime, time
from typing import Annotated, Literal

from pydantic import Field, field_validator, model_validator

from app.plan_limits import DEFAULT_MISSED_AFTER_MINUTES, MissedAfter
from app.validation import MAX_RANGE_DAYS, Dto

Kind = Literal["glucose", "blood_pressure"]
# «ظروف القياس»: what was going on at a reading, one or more of them.
Code = Literal[
    "fasting", "before_meal", "after_meal", "bedtime",
    "before_medicine", "after_medicine", "morning",
    "exertion", "stress", "illness", "other",
]
CODES = Code.__args__
# Where the stomach is: one of these at a time.
MEAL_STATES = ("fasting", "before_meal", "after_meal", "bedtime")
# «حالة القياس» of a reading time: the stomach for glucose, the medicine
# and the time of day for pressure. One at a time, and only for its kind.
GLUCOSE_STATES = ("fasting", "before_meal", "after_meal")
PRESSURE_STATES = ("before_medicine", "after_medicine", "morning")
# Blood pressure is not read against a fast or bedtime.
NOT_FOR_BLOOD_PRESSURE = ("fasting", "before_meal", "bedtime")
Value = Annotated[int, Field(ge=1, le=999)]
Conditions = Annotated[list[Code], Field(max_length=len(CODES))]
MeasurementState = Literal[
    "fasting", "before_meal", "after_meal",
    "before_medicine", "after_medicine", "morning",
]
SkipReason = Literal[
    "forgotten", "equipment_unavailable", "patient_refused", "unwell",
    "other",
]


def check_conditions(kind: str, conditions: list[str]) -> None:
    """Conditions do not repeat, hold one meal state, and suit the kind."""
    if len(set(conditions)) != len(conditions):
        raise ValueError("Conditions cannot repeat.")
    if sum(code in MEAL_STATES for code in conditions) > 1:
        raise ValueError("A reading has one meal state at most.")
    if kind == "blood_pressure" and any(
        code in NOT_FOR_BLOOD_PRESSURE for code in conditions
    ):
        raise ValueError("Blood pressure has no fasting or bedtime.")


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
        # Every reading time names a state of its own kind: the stomach for
        # glucose, the medicine or the morning for pressure.
        allowed = (
            GLUCOSE_STATES if self.kind == "glucose" else PRESSURE_STATES
        )
        for item in self.times:
            if item.measurement_state not in allowed:
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


class ReadingRequest(Dto):
    """A recorded reading or an explicit skip."""

    kind: Kind
    outcome: Literal["read", "skipped"]
    measured_at: datetime | None = None
    glucose_value: Value | None = None
    systolic_value: Value | None = None
    diastolic_value: Value | None = None
    conditions: Conditions = []
    # What «أخرى» was, in the reader's words; only with «أخرى».
    other_text: Annotated[str | None, Field(max_length=60)] = None
    note: Annotated[str | None, Field(max_length=250)] = None
    skip_reason_code: SkipReason | None = None
    skip_reason_note: Annotated[str | None, Field(max_length=250)] = None
    # Sent by builds before 0049, and ignored: fixed ranges judge readings.
    glucose_low: Value | None = None
    glucose_high: Value | None = None
    systolic_limit: Value | None = None
    diastolic_limit: Value | None = None

    @field_validator("other_text", "skip_reason_note")
    @classmethod
    def trimmed(cls, value: str | None) -> str | None:
        """Spaces alone are no words."""
        value = value.strip() if value is not None else None
        return value or None

    @model_validator(mode="after")
    def valid_values(self):
        """A skip has no reading; a reading has the values of its kind."""
        values = (
            self.glucose_value, self.systolic_value, self.diastolic_value
        )
        if self.outcome == "skipped":
            if self.measured_at is not None or any(
                value is not None for value in values
            ):
                raise ValueError("A skipped task has no reading.")
            if self.skip_reason_note and self.skip_reason_code != "other":
                raise ValueError("A skip note requires the other reason.")
        elif self.measured_at is None or (
            self.kind == "glucose"
            and (
                self.glucose_value is None
                or self.systolic_value is not None
                or self.diastolic_value is not None
            )
        ) or (
            self.kind == "blood_pressure"
            and (
                self.glucose_value is not None
                or self.systolic_value is None
                or self.diastolic_value is None
            )
        ):
            raise ValueError("A reading needs values for its kind.")
        elif self.skip_reason_code or self.skip_reason_note:
            raise ValueError("A reading cannot include a skip reason.")
        # The conditions fit the kind; words for «أخرى» need «أخرى».
        check_conditions(self.kind, list(self.conditions))
        if self.other_text is not None and "other" not in self.conditions:
            raise ValueError("Words for «أخرى» need «أخرى».")
        # A blood pressure's systolic is above its diastolic.
        if (
            self.outcome == "read" and self.kind == "blood_pressure"
            and self.systolic_value <= self.diastolic_value
        ):
            raise ValueError("Systolic must exceed diastolic.")
        return self


class ReadingQuery(Dto):
    """Bounded range for readings and calculated occurrences."""

    from_date: date = Field(alias="from")
    to_date: date = Field(alias="to")

    @model_validator(mode="after")
    def valid_range(self):
        """Prevent oversized or reversed requests."""
        if self.to_date < self.from_date:
            raise ValueError("The end date cannot precede the start.")
        if (self.to_date - self.from_date).days >= MAX_RANGE_DAYS:
            raise ValueError(
                f"A request can cover at most {MAX_RANGE_DAYS} days."
            )
        return self
