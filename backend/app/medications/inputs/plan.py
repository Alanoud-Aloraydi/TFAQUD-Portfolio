"""The body of adding a medicine."""

from datetime import date
from typing import Annotated

from pydantic import Field, field_validator, model_validator

from app.medications.inputs.fields import (
    UNIT_BY_FORM,
    DosageForm,
    OptionalText250,
    StrengthUnit,
    StrengthValue,
    Text50,
    english_decimal,
)
from app.medications.inputs.schedule import ScheduleRequest
from app.plan_limits import DEFAULT_MISSED_AFTER_MINUTES, MissedAfter
from app.validation import Dto


class PlanRequest(Dto):
    """The body of adding a medicine."""

    name: Text50
    strength_value: StrengthValue
    strength_unit: StrengthUnit
    dosage_form: DosageForm
    reason_for_use: Annotated[str | None, Field(max_length=100)] = None
    instructions: OptionalText250 = None
    missed_after_minutes: MissedAfter = DEFAULT_MISSED_AFTER_MINUTES
    treatment_starts_on: date
    treatment_ends_on: date | None = None
    # None at all is a medicine taken when needed: no reminders, and its
    # doses are recorded with «سجّل جرعة الآن».
    schedules: Annotated[
        list[ScheduleRequest],
        Field(max_length=24),
    ]

    @field_validator("strength_value", mode="before")
    @classmethod
    def valid_strength_number(cls, value):
        """Accept the strength only in English digits, with a zero before the
        decimal point (0.5, not .5).
        """
        return english_decimal(value)

    @model_validator(mode="after")
    def valid_definition(self):
        """The treatment cannot end before it starts, and the strength's unit
        must fit the dosage form.
        """
        if (
            self.treatment_ends_on is not None
            and self.treatment_ends_on < self.treatment_starts_on
        ):
            raise ValueError("Treatment end cannot precede its start.")
        expected_units = UNIT_BY_FORM[self.dosage_form]
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
