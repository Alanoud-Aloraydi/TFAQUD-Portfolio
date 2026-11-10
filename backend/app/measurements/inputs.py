"""Validated requests for measurement plans and readings."""

from datetime import date, datetime, time
from typing import Annotated, Literal

from pydantic import Field, field_validator, model_validator

from app.validation import Dto

Kind = Literal["glucose", "bp"]
Context = Literal["fasting", "before_meal", "after_meal", "bedtime", "other"]
Condition = Literal["exertion", "after_meal", "stress", "illness"]
# «ظروف القياس»: what was going on at a reading, one or more of them. The
# older `glucose_context` and `condition` (one of each) are among them.
Code = Literal[
    "fasting", "before_meal", "after_meal", "bedtime",
    "exertion", "stress", "illness", "other",
]
CODES = Code.__args__
# Where the stomach is: one of these at a time.
MEAL_STATES = ("fasting", "before_meal", "after_meal", "bedtime")
# Blood pressure is not read against a fast or bedtime.
NOT_FOR_BP = ("fasting", "before_meal", "bedtime")
Value = Annotated[int, Field(ge=1, le=999)]


def check_conditions(kind: str, conditions: list[str]) -> None:
    """Conditions do not repeat, hold one meal state, and suit the kind."""
    if len(set(conditions)) != len(conditions):
        raise ValueError("Conditions cannot repeat.")
    if sum(code in MEAL_STATES for code in conditions) > 1:
        raise ValueError("A reading has one meal state at most.")
    if kind == "bp" and any(code in NOT_FOR_BP for code in conditions):
        raise ValueError("Blood pressure has no fasting or bedtime.")


def legacy_context(kind: str, conditions: list[str]) -> str | None:
    """The one `glucose_context` an older app reads."""
    if kind != "glucose":
        return None
    for code in conditions:
        if code in MEAL_STATES:
            return code
    return "other" if "other" in conditions else None


def legacy_condition(kind: str, conditions: list[str]) -> str | None:
    """The one `condition` an older app reads."""
    for code in conditions:
        if code in ("exertion", "stress", "illness") or (
            kind == "bp" and code == "after_meal"
        ):
            return code
    return None


def from_legacy(*codes: str | None) -> list[str]:
    """Conditions from an older app's `glucose_context` and `condition`."""
    return list(dict.fromkeys(code for code in codes if code is not None))


class ReadingTime(Dto):
    """One reading time of the day, with its conditions.

    An older app sends `glucose_context` instead of `conditions`.
    """

    time_of_day: time
    glucose_context: Context | None = None
    conditions: Annotated[list[Code], Field(max_length=len(CODES))] | None = (
        None
    )

    @model_validator(mode="after")
    def one_shape(self):
        """Send the conditions, or the older single field, not both."""
        if self.conditions is not None and self.glucose_context is not None:
            raise ValueError("Send conditions, or the older field.")
        return self

    @property
    def codes(self) -> list[str]:
        """The reading time's conditions, from the list or from an older app's
        single field.
        """
        if self.conditions is not None:
            return list(self.conditions)
        return from_legacy(self.glucose_context)


# Up to six readings a day: fasting, after each meal, at bedtime.
MAX_READING_TIMES = 6


class PlanRequest(Dto):
    """The reading times of a day, selected weekdays, and a target.

    An older app sends one `time_of_day` and `glucose_context` instead of
    `times`; that is a plan with one reading time.
    """

    kind: Kind
    times: Annotated[
        list[ReadingTime], Field(min_length=1, max_length=MAX_READING_TIMES)
    ]
    weekdays: Annotated[list[int], Field(min_length=1, max_length=7)]
    starts_on: date
    grace_minutes: Literal[30, 60, 120] = 60
    glucose_low: Value | None = None
    glucose_high: Value | None = None
    systolic_limit: Value | None = None
    diastolic_limit: Value | None = None

    @model_validator(mode="before")
    @classmethod
    def one_time_from_an_older_app(cls, data):
        """An older app sends one reading time as top-level fields: read it as
        a list of one.
        """
        if isinstance(data, dict) and "times" not in data and (
            "time_of_day" in data
        ):
            data = dict(data)
            data["times"] = [
                {
                    "time_of_day": data.pop("time_of_day"),
                    "glucose_context": data.pop("glucose_context", None),
                }
            ]
        return data

    @property
    def sorted_times(self) -> list[ReadingTime]:
        """The reading times from the earliest of the day."""
        return sorted(self.times, key=lambda item: item.time_of_day)

    @property
    def time_of_day(self) -> time:
        """The first reading time, the copy a version keeps."""
        return self.sorted_times[0].time_of_day

    @property
    def glucose_context(self) -> str | None:
        """The first reading time's glucose context, kept for an older app."""
        return self.context_of(self.sorted_times[0])

    def context_of(self, item: ReadingTime) -> str | None:
        """The `glucose_context` kept for an older app."""
        if item.conditions is None:
            return item.glucose_context
        return legacy_context(self.kind, item.codes)

    @model_validator(mode="after")
    def valid_plan(self):
        """Require only the targets appropriate to the selected kind."""
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
        # Glucose has a low and a high, in order; blood pressure has both upper
        # limits, systolic above diastolic, and no glucose context.
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
            or any(item.glucose_context is not None for item in self.times)
        ):
            raise ValueError("Blood pressure needs both upper limits.")
        # Each reading time's conditions fit the kind.
        for item in self.times:
            check_conditions(self.kind, item.codes)
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
    value_one: Value | None = None
    value_two: Value | None = None
    glucose_context: Context | None = None
    condition: Condition | None = None
    # One or more; an older app sends `glucose_context` and `condition`.
    conditions: Annotated[list[Code], Field(max_length=len(CODES))] | None = (
        None
    )
    # What «أخرى» was, in the reader's words; only with «أخرى».
    other_condition: Annotated[str | None, Field(max_length=60)] = None
    note: Annotated[str | None, Field(max_length=250)] = None
    glucose_low: Value | None = None
    glucose_high: Value | None = None
    systolic_limit: Value | None = None
    diastolic_limit: Value | None = None

    @field_validator("other_condition")
    @classmethod
    def trimmed(cls, value: str | None) -> str | None:
        """Spaces alone are no words."""
        value = value.strip() if value is not None else None
        return value or None

    @model_validator(mode="after")
    def valid_values(self):
        """A skip has no reading; a reading has the right number of values."""
        # The values fit the outcome and the kind: none for a skip; one for
        # glucose; two for blood pressure.
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
        # The conditions fit the kind, and come in one shape only; words for
        # «أخرى» need «أخرى».
        if self.kind == "bp" and self.glucose_context is not None:
            raise ValueError("Blood pressure has no glucose context.")
        if self.conditions is not None:
            if self.glucose_context is not None or self.condition is not None:
                raise ValueError("Send conditions, or the older two fields.")
            check_conditions(self.kind, list(self.conditions))
        if self.other_condition is not None and "other" not in self.codes:
            raise ValueError("Words for «أخرى» need «أخرى».")
        # A blood pressure's systolic is above its diastolic.
        if (
            self.outcome == "read" and self.kind == "bp"
            and self.value_one <= self.value_two
        ):
            raise ValueError("Systolic must exceed diastolic.")
        # A target sent with a reading fits its kind.
        target = (
            self.glucose_low, self.glucose_high,
            self.systolic_limit, self.diastolic_limit,
        )
        if any(value is not None for value in target):
            if self.outcome != "read":
                raise ValueError("Skipped readings cannot have a target.")
            if self.kind == "glucose" and not (
                self.glucose_low is not None
                and self.glucose_high is not None
                and self.glucose_low < self.glucose_high
                and self.systolic_limit is None
                and self.diastolic_limit is None
            ):
                raise ValueError("A glucose target needs a valid range.")
            if self.kind == "bp" and not (
                self.systolic_limit is not None
                and self.diastolic_limit is not None
                and self.systolic_limit > self.diastolic_limit
                and self.glucose_low is None
                and self.glucose_high is None
            ):
                raise ValueError("Blood pressure needs both upper limits.")
        return self

    @property
    def codes(self) -> list[str]:
        """The reading's conditions, from the list or from an older app's two
        single fields.
        """
        if self.conditions is not None:
            return list(self.conditions)
        return from_legacy(self.glucose_context, self.condition)

    @property
    def stored_context(self) -> str | None:
        """The `glucose_context` kept for an older app."""
        if self.conditions is None:
            return self.glucose_context
        return legacy_context(self.kind, self.codes)

    @property
    def stored_condition(self) -> str | None:
        """The `condition` kept for an older app."""
        if self.conditions is None:
            return self.condition
        return legacy_condition(self.kind, self.codes)


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
