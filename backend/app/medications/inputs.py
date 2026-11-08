"""Validated medication request bodies and query parameters."""

from datetime import date, datetime, time
from decimal import Decimal
import re
from typing import Annotated, Literal

from pydantic import Field, field_validator, model_validator

from app.validation import Dto

Text50 = Annotated[str, Field(min_length=1, max_length=50)]
OptionalText250 = Annotated[str | None, Field(max_length=250)]
DoseValue = Annotated[
    Decimal,
    Field(gt=0, max_digits=10, decimal_places=3),
]
StrengthValue = Annotated[
    Decimal,
    Field(gt=0, max_digits=10, decimal_places=3),
]

DosageForm = Literal[
    "tablet", "capsule", "liquid", "drops", "inhaler", "injection"
]
DoseUnit = Literal["tablet", "capsule", "mL", "drop", "puff", "unit"]
StrengthUnit = Literal[
    "mg", "mcg", "mg/mL", "mg/5mL", "mcg/dose", "unit/mL", "%"
]
SkipReason = Literal[
    "forgotten",
    "unavailable",
    "side_effects",
    "patient_refused",
    "other",
]

_UNIT_BY_FORM = {
    "tablet": "tablet",
    "capsule": "capsule",
    "liquid": "mL",
    "drops": "drop",
    "inhaler": "puff",
    "injection": {"mL", "unit"},
}

_ENGLISH_DECIMAL = re.compile(r"^(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$")


def _english_decimal(value):
    """Reject localized digits and decimal text without a leading zero."""
    if isinstance(value, str) and not _ENGLISH_DECIMAL.fullmatch(value):
        raise ValueError("Use English digits with a leading zero.")
    return value


# «نذكرك كل … يوم»: from every day to every 90 days.
MAX_INTERVAL_DAYS = 90


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
        return _english_decimal(value)

    @model_validator(mode="after")
    def valid_days(self):
        if (self.repeat == "interval") != (self.interval_days is not None):
            raise ValueError("Only an interval dose has interval days.")
        if self.repeat == "interval":
            if self.weekdays or self.month_days:
                raise ValueError("An interval dose has no other days.")
        elif self.repeat == "weekly":
            if not self.weekdays:
                raise ValueError("Choose at least one weekday.")
            if self.month_days:
                raise ValueError("A weekly dose has no days of the month.")
            if len(set(self.weekdays)) != len(self.weekdays):
                raise ValueError("Weekdays cannot repeat.")
            if any(day < 1 or day > 7 for day in self.weekdays):
                raise ValueError("Weekdays must be between 1 and 7.")
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


class PlanRequest(Dto):
    name: Text50
    strength_value: StrengthValue
    strength_unit: StrengthUnit
    dosage_form: DosageForm
    reason_for_use: Annotated[str | None, Field(max_length=100)] = None
    instructions: OptionalText250 = None
    missed_after_minutes: Literal[30, 60, 120] = 60
    treatment_starts_on: date
    treatment_ends_on: date | None = None
    schedules: Annotated[
        list[ScheduleRequest],
        Field(min_length=1, max_length=24),
    ]

    @field_validator("strength_value", mode="before")
    @classmethod
    def valid_strength_number(cls, value):
        return _english_decimal(value)

    @model_validator(mode="after")
    def valid_definition(self):
        if (
            self.treatment_ends_on is not None
            and self.treatment_ends_on < self.treatment_starts_on
        ):
            raise ValueError("Treatment end cannot precede its start.")
        expected_units = _UNIT_BY_FORM[self.dosage_form]
        if isinstance(expected_units, str):
            expected_units = {expected_units}
        if any(
            item.dose_unit not in expected_units
            for item in self.schedules
        ):
            raise ValueError("Dose unit does not match the dosage form.")
        weekly = [item for item in self.schedules if item.repeat == "weekly"]
        monthly = [item for item in self.schedules if item.repeat == "monthly"]
        occurrences = {
            (item.time_of_day, day) for item in weekly for day in item.weekdays
        }
        count = sum(len(item.weekdays) for item in weekly)
        if len(occurrences) != count:
            raise ValueError("Dose times cannot repeat on one weekday.")
        # A weekly and a monthly dose at one time would meet on some day;
        # two every few days at one time meet on the first day.
        interval = [item.time_of_day for item in self.schedules
                    if item.repeat == "interval"]
        weekly_times = {item.time_of_day for item in weekly}
        monthly_times = {item.time_of_day for item in monthly}
        if (
            weekly_times & monthly_times
            or len(set(interval)) != len(interval)
            or set(interval) & (weekly_times | monthly_times)
        ):
            raise ValueError("One dose time repeats in one way only.")
        # Two monthly doses at one time never share a day of the month.
        days = {
            (item.time_of_day, day)
            for item in monthly
            for day in item.month_days
        }
        if len(days) != sum(len(item.month_days) for item in monthly):
            raise ValueError(
                "Dose times cannot repeat on one day of the month."
            )
        return self


class RevisePlanRequest(PlanRequest):
    expected_version_number: Annotated[int, Field(ge=1)]
    effective_from_on: date | None = None


class CancelPendingRequest(Dto):
    expected_version_number: Annotated[int, Field(ge=1)]


class DoseRecordRequest(Dto):
    outcome: Literal["taken", "skipped"]
    taken_at: datetime | None = None
    skip_reason_code: SkipReason | None = None
    skip_reason_note: OptionalText250 = None

    @model_validator(mode="after")
    def valid_outcome(self):
        if self.outcome == "taken":
            if self.taken_at is None:
                raise ValueError("Taken doses require the actual time.")
            if self.skip_reason_code or self.skip_reason_note:
                raise ValueError("Taken doses cannot include a skip reason.")
        elif self.taken_at is not None:
            raise ValueError("Skipped doses cannot include a taken time.")
        if self.skip_reason_note and self.skip_reason_code != "other":
            raise ValueError("A skip note requires the other reason.")
        return self


class OccurrenceQuery(Dto):
    from_date: date = Field(validation_alias="from")
    to_date: date = Field(validation_alias="to")
    plan_id: str | None = None

    @model_validator(mode="after")
    def valid_range(self):
        if self.to_date < self.from_date:
            raise ValueError("The end date cannot precede the start date.")
        if (self.to_date - self.from_date).days > 31:
            raise ValueError("A request can cover at most 32 days.")
        return self
