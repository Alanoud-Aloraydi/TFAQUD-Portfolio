"""The measurement plans: list, add, edit, stop."""

from flask import jsonify

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.extensions import get_clock
from app.measurements.blueprint import MEMBERS, bp
from app.measurements.inputs import PlanRequest, RevisePlanRequest
from app.measurements.queries import MeasurementQueries
from app.measurements.route_helpers import parse_uuid
from app.measurements.service import MeasurementService
from app.validation import parse_json_body


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
