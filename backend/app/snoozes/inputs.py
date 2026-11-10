"""The body of a snooze."""

from datetime import date, time
from typing import Literal
from uuid import UUID

from pydantic import Field, model_validator

from app.validation import Dto


class SnoozeRequest(Dto):
    """One dose or reading time put off for `minutes` from now.

    A dose is its schedule (`task_id`) on its day; a reading time is its
    plan version (`task_id`) on its day at `time_of_day`, since a version
    can read more than once a day.
    """

    task: Literal["dose", "measurement"]
    task_id: UUID
    scheduled_on: date
    time_of_day: time | None = None
    minutes: int = Field(ge=1, le=240)

    @model_validator(mode="after")
    def reading_time_given(self):
        """A reading time names its time; a dose's comes from its
        schedule."""
        if self.task == "measurement" and self.time_of_day is None:
            raise ValueError("A reading time needs its time_of_day.")
        return self
