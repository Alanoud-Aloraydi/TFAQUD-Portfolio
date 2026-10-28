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


class ScheduleRequest(Dto):
    time_of_day: time
    dose_value: DoseValue
    dose_unit: DoseUnit
    weekdays: Annotated[list[int], Field(min_length=1, max_length=7)]
    instructions: OptionalText250 = None

    @field_validator("dose_value", mode="before")
    @classmethod
    def valid_dose_number(cls, value):
        return _english_decimal(value)

    @model_validator(mode="after")
    def valid_weekdays(self):
        if len(set(self.weekdays)) != len(self.weekdays):
            raise ValueError("Weekdays cannot repeat.")
        if any(day < 1 or day > 7 for day in self.weekdays):
            raise ValueError("Weekdays must be between 1 and 7.")
        return self


class PlanRequest(Dto):
    name: Text50
    strength_value: StrengthValue
    strength_unit: StrengthUnit
    dosage_form: DosageForm
    reason_for_use: Annotated[str | None, Field(max_length=100)] = None
    instructions: OptionalText250 = None
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
    effective_from_on: date | None = None


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
