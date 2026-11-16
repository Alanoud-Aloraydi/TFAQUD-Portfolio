"""The body of a reading or an explicit skip."""

from datetime import datetime
from typing import Annotated, Literal

from pydantic import Field, field_validator, model_validator

from app.measurements.inputs.fields import (
    DIASTOLIC_RANGE,
    GLUCOSE_RANGE,
    SYSTOLIC_RANGE,
    Conditions,
    Kind,
    SkipReason,
    Value,
    check_conditions,
    in_range,
)
from app.validation import Dto


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
        # A blood pressure's systolic is above its diastolic, and every
        # number is one a body can have.
        if self.outcome == "read":
            if self.kind == "blood_pressure":
                if self.systolic_value <= self.diastolic_value:
                    raise ValueError("Systolic must exceed diastolic.")
                in_range(self.systolic_value, SYSTOLIC_RANGE, "systolic")
                in_range(self.diastolic_value, DIASTOLIC_RANGE, "diastolic")
            else:
                in_range(self.glucose_value, GLUCOSE_RANGE, "glucose")
        return self
