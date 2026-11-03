"""Validated appointment input and state transitions."""

from datetime import date, datetime, time
from typing import Annotated, Literal
from uuid import UUID

from pydantic import Field, model_validator

from app.validation import Dto


class AppointmentRequest(Dto):
    """A single appointment with a circle companion."""

    specialty: Annotated[str, Field(min_length=1, max_length=80)]
    kind: Literal["follow_up", "test", "imaging", "remote"]
    scheduled_on: date
    time_of_day: time
    place: Annotated[str | None, Field(max_length=160)] = None
    remote_method: Literal["video", "phone"] | None = None
    companion_account_id: UUID

    @model_validator(mode="after")
    def valid_location(self):
        """Remote visits have a method; physical visits have a place."""
        if not self.specialty.strip():
            raise ValueError("A specialty is required.")
        if self.time_of_day.tzinfo is not None:
            raise ValueError("The appointment time must be local time.")
        if self.kind == "remote":
            if self.remote_method is None or self.place is not None:
                raise ValueError("A remote method is required.")
        elif self.remote_method is not None or not (
            self.place and self.place.strip()
        ):
            raise ValueError("A place is required.")
        return self


class AppointmentStatusRequest(Dto):
    """An explicit completion or cancellation."""

    status: Literal["completed", "cancelled"]
    expected_updated_at: datetime


class ReviseAppointmentRequest(AppointmentRequest):
    """An edit against the version last read by the client."""

    expected_updated_at: datetime
