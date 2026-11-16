"""Reading the parts of a measurement request, and answering a saved
reading."""

from datetime import date, time
from uuid import UUID

from flask import request
from pydantic import ValidationError

from app.accounts import accounts_by_id
from app.errors import NotFound, ValidationFailed
from app.measurements.inputs import ReadingQuery
from app.measurements.queries import reading_response
from app.measurements.ranges import patient_codes
from app.measurements.service import planned_state


def parse_uuid(value: str) -> UUID:
    """Parse a path identifier without exposing parser errors."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None


def parse_date(value: str) -> date:
    """Parse an ISO calendar date in a path."""
    try:
        return date.fromisoformat(value)
    except (ValueError, TypeError):
        raise ValidationFailed(code="invalid_measurement_date") from None


def parse_time(value: str | None) -> time | None:
    """The reading time of a task, «HH:MM», or None when not given."""
    if value is None:
        return None
    try:
        parsed = time.fromisoformat(value)
    except (ValueError, TypeError):
        raise ValidationFailed(code="invalid_measurement_time") from None
    if parsed.tzinfo is not None:
        raise ValidationFailed(code="invalid_measurement_time")
    return parsed


def answer_reading(session, reading) -> dict:
    """A saved reading as the lists show it: judged by its normal range,
    with who recorded it."""
    recorder = accounts_by_id(
        session,
        {reading.recorded_by_account_id}
        if reading.recorded_by_account_id
        else set(),
    )
    return reading_response(
        reading, recorder,
        codes=patient_codes(session, reading.care_circle_id),
        planned=planned_state(session, reading),
    )


def parse_range() -> ReadingQuery:
    """Validate query parameters using the normal API error shape."""
    try:
        return ReadingQuery.model_validate(request.args.to_dict())
    except ValidationError as error:
        raise ValidationFailed(code="invalid_measurement_range") from error
