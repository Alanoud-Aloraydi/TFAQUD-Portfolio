"""Parsing and response helpers for medication routes."""

from uuid import UUID

from flask import request
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.accounts import recorder_response
from app.errors import NotFound, ValidationFailed
from app.medications.inputs import OccurrenceQuery
from app.models import Account


def uuid_value(value: str) -> UUID:
    """Parse a path UUID without exposing parser details."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None


def occurrence_query() -> OccurrenceQuery:
    """Validate occurrence query parameters in the shared error shape."""
    try:
        return OccurrenceQuery.model_validate(request.args.to_dict())
    except ValidationError as exc:
        details = [
            {
                "field": ".".join(str(part) for part in error["loc"]),
                "code": error["type"],
                "message": error["msg"],
            }
            for error in exc.errors()
        ]
        raise ValidationFailed(details=details) from exc


def dose_record_response(session: Session, record) -> dict:
    """Serialize the outcome returned after an idempotent write."""
    recorder = (
        session.get(Account, record.recorded_by_account_id)
        if record.recorded_by_account_id
        else None
    )
    return {
        "id": str(record.id),
        "schedule_id": str(record.schedule_id),
        "scheduled_on": record.scheduled_on.isoformat(),
        "outcome": record.outcome,
        "taken_at": (
            record.taken_at.isoformat() if record.taken_at else None
        ),
        "skip_reason_code": record.skip_reason_code,
        "skip_reason_note": record.skip_reason_note,
        "recorded_at": record.recorded_at.isoformat(),
        "recorded_by": recorder_response(recorder),
    }
