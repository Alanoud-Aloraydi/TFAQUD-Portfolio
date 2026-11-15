"""The body of recording a dose, and the query of listing doses."""

from datetime import date, datetime
from typing import Literal

from pydantic import Field, model_validator

from app.medications.inputs.fields import OptionalText250, SkipReason
from app.validation import MAX_RANGE_DAYS, Dto


class DoseRecordRequest(Dto):
    """The body of recording a dose: taken (at a time) or skipped (with an
    optional reason).
    """

    outcome: Literal["taken", "skipped"]
    taken_at: datetime | None = None
    skip_reason_code: SkipReason | None = None
    skip_reason_note: OptionalText250 = None

    @model_validator(mode="after")
    def valid_outcome(self):
        """A taken dose has its time and no skip reason; a skipped dose has no
        taken time.
        """
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
    """The query of listing doses: from and to dates, optionally one medicine.
    """

    from_date: date = Field(validation_alias="from")
    to_date: date = Field(validation_alias="to")
    plan_id: str | None = None

    @model_validator(mode="after")
    def valid_range(self):
        """The range runs forward and covers at most MAX_RANGE_DAYS days."""
        if self.to_date < self.from_date:
            raise ValueError("The end date cannot precede the start date.")
        if (self.to_date - self.from_date).days >= MAX_RANGE_DAYS:
            raise ValueError(
                f"A request can cover at most {MAX_RANGE_DAYS} days."
            )
        return self
