"""Editing a medicine, stopping it, cancelling an edit not started."""

from flask import jsonify

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.extensions import get_clock
from app.medications.blueprint import bp
from app.medications.inputs import CancelPendingRequest, RevisePlanRequest
from app.medications.plans import MedicationPlanService
from app.medications.queries import MedicationQueries
from app.medications.route_helpers import uuid_value
from app.validation import parse_json_body


@bp.put("/medication-plans/<plan_id>")
@require_circle_role(CircleRole.MANAGER, area="medications")
def revise_plan(circle_id, plan_id):
    """Edit a medicine (a manager only); `expected_version_number` stops an
    edit made on data that changed meanwhile.
    """
    body = parse_json_body(RevisePlanRequest)
    with transaction() as session:
        plan = MedicationPlanService(
            session, get_clock().now()
        ).revise(
            uuid_value(circle_id),
            uuid_value(plan_id),
            uuid_value(current_auth().user_id),
            body,
        )
        result = MedicationQueries(session, get_clock().now()).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result)


@bp.post("/medication-plans/<plan_id>/stop")
@require_circle_role(CircleRole.MANAGER, area="medications")
def stop_plan(circle_id, plan_id):
    """Stop a medicine (a manager only); its history stays."""
    with transaction() as session:
        plan = MedicationPlanService(
            session, get_clock().now()
        ).stop(
            uuid_value(circle_id),
            uuid_value(plan_id),
            uuid_value(current_auth().user_id),
        )
        result = MedicationQueries(session, get_clock().now()).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result)


@bp.post("/medication-plans/<plan_id>/cancel-pending")
@require_circle_role(CircleRole.MANAGER, area="medications")
def cancel_pending_plan(circle_id, plan_id):
    """Cancel an edit that has not started yet (a manager only)."""
    body = parse_json_body(CancelPendingRequest)
    with transaction() as session:
        plan = MedicationPlanService(
            session, get_clock().now()
        ).cancel_pending(
            uuid_value(circle_id),
            uuid_value(plan_id),
            body.expected_version_number,
        )
        result = MedicationQueries(session, get_clock().now()).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result)
