"""Authorized circle measurement endpoints."""

from datetime import date
from uuid import UUID

from flask import Blueprint, jsonify, request
from pydantic import ValidationError

from app.accounts import accounts_by_id
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock
from app.measurements.inputs import PlanRequest, ReadingQuery
from app.measurements.inputs import ReadingRequest, RevisePlanRequest
from app.measurements.queries import MeasurementQueries, reading_response
from app.measurements.service import MeasurementService
from app.models import MeasurementPlanVersion
from app.validation import parse_json_body

bp = Blueprint(
    "measurements", __name__, url_prefix="/api/v1/circles/<circle_id>"
)
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.PATIENT,
    CircleRole.SIMPLIFIED_PATIENT,
)


def _uuid(value: str) -> UUID:
    """Parse a path identifier without exposing parser errors."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None


def _date(value: str) -> date:
    """Parse an ISO calendar date in a path."""
    try:
        return date.fromisoformat(value)
    except (ValueError, TypeError):
        raise ValidationFailed(code="invalid_measurement_date") from None


def _range() -> ReadingQuery:
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
            _uuid(circle_id)
        )
    response = jsonify(measurement_plans=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-targets")
@require_circle_role(*MEMBERS)
def list_targets(circle_id):
    """Read the patient's saved and active scheduled targets."""
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).targets(
            _uuid(circle_id)
        )
    response = jsonify(measurement_targets=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/measurement-plans")
@require_circle_role(CircleRole.MANAGER)
def create_plan(circle_id):
    """Add a scheduled measurement plan."""
    body = parse_json_body(PlanRequest)
    with transaction() as session:
        plan = MeasurementService(session, get_clock().now()).create(
            _uuid(circle_id), _uuid(current_auth().user_id), body
        )
        values = MeasurementQueries(session, get_clock().now()).plans(
            _uuid(circle_id)
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
@require_circle_role(CircleRole.MANAGER)
def revise_plan(circle_id, plan_id):
    """Apply a plan revision from a future date."""
    body = parse_json_body(RevisePlanRequest)
    with transaction() as session:
        plan = MeasurementService(session, get_clock().now()).revise(
            _uuid(circle_id), _uuid(plan_id), body
        )
        values = MeasurementQueries(session, get_clock().now()).plans(
            _uuid(circle_id)
        )
    return jsonify(
        measurement_plan=next(
            item for item in values if item["id"] == str(plan.id)
        )
    )


@bp.post("/measurement-plans/<plan_id>/stop")
@require_circle_role(CircleRole.MANAGER)
def stop_plan(circle_id, plan_id):
    """Stop future tasks while retaining history."""
    with transaction() as session:
        plan = MeasurementService(session, get_clock().now()).stop(
            _uuid(circle_id), _uuid(plan_id)
        )
        values = MeasurementQueries(session, get_clock().now()).plans(
            _uuid(circle_id)
        )
    return jsonify(
        measurement_plan=next(
            item for item in values if item["id"] == str(plan.id)
        )
    )


@bp.get("/measurement-occurrences")
@require_circle_role(*MEMBERS)
def list_occurrences(circle_id):
    """Calculate tasks for at most 32 calendar days."""
    dates = _range()
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).occurrences(
            _uuid(circle_id), dates.from_date, dates.to_date
        )
    response = jsonify(measurement_occurrences=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings")
@require_circle_role(*MEMBERS)
def list_readings(circle_id):
    """Read actual measurements and explicit skips."""
    dates = _range()
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).readings(
            _uuid(circle_id), dates.from_date, dates.to_date
        )
    response = jsonify(measurement_readings=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings/export")
@require_circle_role(*MEMBERS)
def export_readings(circle_id):
    """Return saved measurements for an authorized PDF export."""
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).all_readings(
            _uuid(circle_id)
        )
    response = jsonify(measurement_readings=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/measurement-readings")
@require_circle_role(*MEMBERS)
def create_standalone_reading(circle_id):
    """Save an unlinked reading without completing a scheduled task."""
    body = parse_json_body(ReadingRequest)
    with transaction() as session:
        record = MeasurementService(session, get_clock().now()).record(
            _uuid(circle_id), _uuid(current_auth().user_id), body
        )
        accounts = accounts_by_id(
            session,
            {record.recorded_by_account_id}
            if record.recorded_by_account_id
            else set(),
        )
        value = reading_response(record, accounts=accounts)
    return jsonify(measurement_reading=value), 201


@bp.put("/measurement-records/<version_id>/<scheduled_on>")
@require_circle_role(*MEMBERS)
def record_task(circle_id, version_id, scheduled_on):
    """Save the reading or skip for one scheduled occurrence."""
    body = parse_json_body(ReadingRequest)
    with transaction() as session:
        record = MeasurementService(session, get_clock().now()).record(
            _uuid(circle_id),
            _uuid(current_auth().user_id),
            body,
            version_id=_uuid(version_id),
            scheduled_on=_date(scheduled_on),
        )
        version = session.get(MeasurementPlanVersion, record.plan_version_id)
        accounts = accounts_by_id(
            session,
            {record.recorded_by_account_id}
            if record.recorded_by_account_id
            else set(),
        )
        value = reading_response(record, version, accounts)
    return jsonify(measurement_reading=value)


@bp.post("/measurement-readings/<reading_id>/follow-up")
@require_circle_role(*MEMBERS)
def follow_up(circle_id, reading_id):
    """Mark an out-of-range reading as reviewed."""
    with transaction() as session:
        record = MeasurementService(session, get_clock().now()).follow_up(
            _uuid(circle_id), _uuid(reading_id)
        )
        version = (
            session.get(MeasurementPlanVersion, record.plan_version_id)
            if record.plan_version_id
            else None
        )
        accounts = accounts_by_id(
            session,
            {record.recorded_by_account_id}
            if record.recorded_by_account_id
            else set(),
        )
        value = reading_response(record, version, accounts)
    return jsonify(measurement_reading=value)
