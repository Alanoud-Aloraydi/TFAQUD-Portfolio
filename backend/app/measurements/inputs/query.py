"""The query of listing readings and tasks."""

from datetime import date

from pydantic import Field, model_validator

from app.validation import MAX_RANGE_DAYS, Dto


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
