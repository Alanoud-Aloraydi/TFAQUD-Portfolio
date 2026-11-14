"""Validated appointment input and state transitions."""

from datetime import date, datetime, time
from typing import Annotated, Literal
from uuid import UUID

from pydantic import Field, model_validator

from app.appointments.kinds import APPOINTMENT_KINDS
from app.validation import Dto


class AppointmentRequest(Dto):
    """A single appointment, with the circle members going to it, if any."""

    # The clinic or doctor, as typed; optional.
    specialty: Annotated[str | None, Field(max_length=80)] = None
    kind: str
    other_text: Annotated[str | None, Field(max_length=80)] = None
    scheduled_on: date
    time_of_day: time
    place: Annotated[str | None, Field(max_length=160)] = None
    remote_method: Literal["video", "phone"] | None = None
    # Who goes with the patient: none, one or more managers of the circle.
    companion_account_ids: list[UUID] = Field(default_factory=list)

    @model_validator(mode="after")
    def valid_location(self):
        """Remote visits have a method; physical visits have a place."""
        # A known kind; a type of its own only for «أخرى»; a local time;
        # each companion once.
        if self.kind not in APPOINTMENT_KINDS:
            raise ValueError("Unknown appointment kind.")
        if self.kind == "other":
            if not self.other_text or not self.other_text.strip():
                raise ValueError("A custom appointment type is required.")
        elif self.other_text is not None:
            raise ValueError("A custom type is only valid for other visits.")
        if self.time_of_day.tzinfo is not None:
            raise ValueError("The appointment time must be local time.")
        if len(self.companion_account_ids) != len(
            set(self.companion_account_ids)
        ):
            raise ValueError("Appointment companions must be unique.")
        # A remote visit has its method and no place; any other has a place.
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
