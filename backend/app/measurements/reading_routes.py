"""The reading endpoints: the normal ranges, the tasks and saved readings
of some days, the first day with one, the export; recording a reading,
outside a plan or for a task, and following one up."""

from flask import Blueprint, jsonify, request

from app.auth.decorators import current_auth
from app.authz import require_circle_role
from app.database import transaction
from app.extensions import get_clock
from app.measurements.inputs import ReadingRequest
from app.measurements.queries import MeasurementQueries
from app.measurements.reading_queries import first_reading_on
from app.measurements.routes import (
    EDITORS,
    MEMBERS,
    answer_reading,
    parse_date,
    parse_range,
    parse_time,
    parse_uuid,
)
from app.measurements.service import MeasurementService
from app.push.attention import send_all
from app.push.attention import unusual_reading_pushes
from app.validation import parse_json_body

bp = Blueprint(
    "measurement_readings", __name__, url_prefix="/api/v1/circles/<circle_id>"
)


@bp.get("/measurement-ranges")
@require_circle_role(*MEMBERS)
def list_ranges(circle_id):
    """Read the normal ranges the patient's readings are judged by."""
    with transaction() as session:
        value = MeasurementQueries(session, get_clock().now()).ranges(
            parse_uuid(circle_id)
        )
    response = jsonify(measurement_ranges=value)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-occurrences")
@require_circle_role(*MEMBERS)
def list_occurrences(circle_id):
    """Calculate tasks for at most 35 calendar days."""
    dates = parse_range()
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).occurrences(
            parse_uuid(circle_id), dates.from_date, dates.to_date
        )
    response = jsonify(measurement_occurrences=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings")
@require_circle_role(*MEMBERS)
def list_readings(circle_id):
    """Read actual measurements and explicit skips."""
    dates = parse_range()
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).readings(
            parse_uuid(circle_id), dates.from_date, dates.to_date
        )
    response = jsonify(measurement_readings=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings/first")
@require_circle_role(*MEMBERS)
def first_reading(circle_id):
    """The patient's first day with a saved reading or skip, or null."""
    with transaction() as session:
        day = first_reading_on(session, parse_uuid(circle_id))
    response = jsonify(first_reading_on=day.isoformat() if day else None)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/measurement-readings/export")
@require_circle_role(*MEMBERS)
def export_readings(circle_id):
    """Return saved measurements for an authorized PDF export."""
    with transaction() as session:
        values = MeasurementQueries(session, get_clock().now()).all_readings(
            parse_uuid(circle_id)
        )
    response = jsonify(measurement_readings=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/measurement-readings")
@require_circle_role(*EDITORS)
def create_standalone_reading(circle_id):
    """Save a reading taken outside a plan."""
    body = parse_json_body(ReadingRequest)
    circle, actor = parse_uuid(circle_id), parse_uuid(current_auth().user_id)
    with transaction() as session:
        reading = MeasurementService(session, get_clock().now()).record(
            circle, actor, body
        )
        value = answer_reading(session, reading)
        pushes = unusual_reading_pushes(
            session, circle, reading, value["level"], actor
        )
    send_all(pushes)
    return jsonify(measurement_reading=value), 201


@bp.put("/measurement-readings/<plan_version_id>/<scheduled_on>")
@require_circle_role(*EDITORS)
def record_task(circle_id, plan_version_id, scheduled_on):
    """Save the reading or skip for one scheduled occurrence: a version's
    reading time (`?time=HH:MM`) on a day. Without `time`, the version's
    only reading time."""
    body = parse_json_body(ReadingRequest)
    scheduled_time = parse_time(request.args.get("time"))
    circle, actor = parse_uuid(circle_id), parse_uuid(current_auth().user_id)
    with transaction() as session:
        reading = MeasurementService(session, get_clock().now()).record(
            circle,
            actor,
            body,
            plan_version_id=parse_uuid(plan_version_id),
            scheduled_on=parse_date(scheduled_on),
            scheduled_time=scheduled_time,
        )
        value = answer_reading(session, reading)
        # Outside its normal range: the others are told at once.
        pushes = unusual_reading_pushes(
            session, circle, reading, value["level"], actor
        )
    send_all(pushes)
    return jsonify(measurement_reading=value)


@bp.post("/measurement-readings/<reading_id>/follow-up")
@require_circle_role(*EDITORS)
def follow_up(circle_id, reading_id):
    """Mark an out-of-range reading as reviewed."""
    with transaction() as session:
        reading = MeasurementService(session, get_clock().now()).follow_up(
            parse_uuid(circle_id), parse_uuid(reading_id)
        )
        value = answer_reading(session, reading)
    return jsonify(measurement_reading=value)
