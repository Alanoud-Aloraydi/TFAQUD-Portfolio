"""The measurement plan endpoints under /api/v1/circles/<circle_id>:
list, add, edit, stop; and what every measurement endpoint shares."""

from datetime import date, time
from uuid import UUID

from flask import Blueprint, jsonify, request
from pydantic import ValidationError

from app.accounts import accounts_by_id
from app.auth.decorators import current_auth
from app.authz import CircleRole, require_circle_role
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock
from app.measurements.inputs import (
    PlanRequest,
    ReadingQuery,
    RevisePlanRequest,
)
from app.measurements.plans import planned_state
from app.measurements.queries import MeasurementQueries
from app.measurements.ranges import patient_codes
from app.measurements.responses import reading_response
from app.measurements.service import MeasurementService
from app.validation import parse_json_body


bp = Blueprint(
    "measurements", __name__, url_prefix="/api/v1/circles/<circle_id>"
)

MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)

EDITORS = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


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


@bp.get("/measurement-plans")
@require_circle_role(*MEMBERS)
def list_plans(circle_id):
    """Read the selected circle's plans."""
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).plans(
            parse_uuid(circle_id)
        )
    response = jsonify(measurement_plans=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/measurement-plans")
@require_circle_role(CircleRole.MANAGER, area="measurements")
def create_plan(circle_id):
    """Add a scheduled measurement plan."""
    body = parse_json_body(PlanRequest)
    # Save the plan, and answer it as the list shows it.
    with transaction() as session:
        plan = MeasurementService(session, get_clock().now()).create(
            parse_uuid(circle_id), parse_uuid(current_auth().user_id), body
        )
        values = MeasurementQueries(session, get_clock().now()).plans(
            parse_uuid(circle_id)
        )
    return (
        jsonify(
            measurement_plan=next(
                item for item in values if item["id"] == str(plan.id)
            )
        ),
        201,
    )


@bp.put("/measurement-plans/<plan_id>")
@require_circle_role(CircleRole.MANAGER, area="measurements")
def revise_plan(circle_id, plan_id):
    """Apply a plan revision from a future date."""
    body = parse_json_body(RevisePlanRequest)
    # Save the edit, and answer the plan as the list shows it.
    with transaction() as session:
        plan = MeasurementService(session, get_clock().now()).revise(
            parse_uuid(circle_id),
            parse_uuid(plan_id),
            parse_uuid(current_auth().user_id),
            body,
        )
        values = MeasurementQueries(session, get_clock().now()).plans(
            parse_uuid(circle_id)
        )
    return jsonify(
        measurement_plan=next(
            item for item in values if item["id"] == str(plan.id)
        )
    )


@bp.post("/measurement-plans/<plan_id>/stop")
@require_circle_role(CircleRole.MANAGER, area="measurements")
def stop_plan(circle_id, plan_id):
    """Stop future tasks while retaining history."""
    with transaction() as session:
        plan = MeasurementService(session, get_clock().now()).stop(
            parse_uuid(circle_id),
            parse_uuid(plan_id),
            parse_uuid(current_auth().user_id),
        )
        values = MeasurementQueries(session, get_clock().now()).plans(
            parse_uuid(circle_id)
        )
    return jsonify(
        measurement_plan=next(
            item for item in values if item["id"] == str(plan.id)
        )
    )
