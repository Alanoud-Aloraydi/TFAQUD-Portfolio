"""Recording a reading, outside a plan or for a task, and following one
up."""

from flask import jsonify, request

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.database import transaction
from app.extensions import get_clock
from app.measurements.blueprint import EDITORS, bp
from app.measurements.inputs import ReadingRequest
from app.measurements.route_helpers import (
    answer_reading,
    parse_date,
    parse_time,
    parse_uuid,
)
from app.measurements.service import MeasurementService
from app.push.messages.attention import send_all
from app.push.messages.attention_events import unusual_reading_pushes
from app.validation import parse_json_body


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
