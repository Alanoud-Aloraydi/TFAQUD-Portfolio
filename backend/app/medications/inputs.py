"""Validated medication request bodies and query parameters."""

from datetime import date, datetime, time
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import Field, model_validator

from app.validation import Dto

Text50 = Annotated[str, Field(min_length=1, max_length=50)]
OptionalText250 = Annotated[str | None, Field(max_length=250)]
DoseValue = Annotated[
    Decimal,
    Field(gt=0, max_digits=10, decimal_places=3),
]

DosageForm = Literal[
    "tablet", "capsule", "liquid", "drops", "inhaler", "injection"
]
DoseUnit = Literal["tablet", "capsule", "mL", "drop", "puff", "unit"]

_UNIT_BY_FORM = {
    "tablet": "tablet",
    "capsule": "capsule",
    "liquid": "mL",
    "drops": "drop",
    "inhaler": "puff",
    "injection": "unit",
}


class ScheduleRequest(Dto):
    time_of_day: time
    dose_value: DoseValue
    dose_unit: DoseUnit
    weekdays: Annotated[list[int], Field(min_length=1, max_length=7)]
    instructions: OptionalText250 = None

    @model_validator(mode="after")
    def valid_weekdays(self):
        if len(set(self.weekdays)) != len(self.weekdays):
            raise ValueError("Weekdays cannot repeat.")
        if any(day < 1 or day > 7 for day in self.weekdays):
            raise ValueError("Weekdays must be between 1 and 7.")
        return self


class PlanRequest(Dto):
    name: Text50
    strength_text: Annotated[str | None, Field(max_length=50)] = None
    dosage_form: DosageForm
    reason_for_use: Annotated[str | None, Field(max_length=100)] = None
    instructions: OptionalText250 = None
    treatment_starts_on: date
    treatment_ends_on: date | None = None
    schedules: Annotated[
        list[ScheduleRequest],
        Field(min_length=1, max_length=24),
    ]

    @model_validator(mode="after")
    def valid_definition(self):
        if (
            self.treatment_ends_on is not None
            and self.treatment_ends_on < self.treatment_starts_on
        ):
            raise ValueError("Treatment end cannot precede its start.")
        expected_unit = _UNIT_BY_FORM[self.dosage_form]
        if any(item.dose_unit != expected_unit for item in self.schedules):
            raise ValueError("Dose unit does not match the dosage form.")
        occurrences = {
            (item.time_of_day, day)
            for item in self.schedules
            for day in item.weekdays
        }
        count = sum(len(item.weekdays) for item in self.schedules)
        if len(occurrences) != count:
            raise ValueError("Dose times cannot repeat on one weekday.")
        return self


class RevisePlanRequest(PlanRequest):
    expected_version_number: Annotated[int, Field(ge=1)]


class DoseRecordRequest(Dto):
    outcome: Literal["taken", "skipped"]
    taken_at: datetime | None = None
    skip_reason_code: Annotated[str | None, Field(max_length=40)] = None
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
