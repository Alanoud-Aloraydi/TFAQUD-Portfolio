"""The body of «سجّل جرعة الآن»."""

from datetime import datetime
from uuid import UUID

from pydantic import field_validator

from app.medications.inputs.fields import DoseUnit, DoseValue, english_decimal
from app.validation import Dto


class ExtraDoseRequest(Dto):
    """One extra dose: the medicine, when it was taken, and how much."""

    plan_id: UUID
    taken_at: datetime
    dose_value: DoseValue
    dose_unit: DoseUnit

    @field_validator("dose_value", mode="before")
    @classmethod
    def valid_dose_number(cls, value):
        """Accept the dose only in English digits, with a zero before the
        decimal point (0.5, not .5).
        """
        return english_decimal(value)
