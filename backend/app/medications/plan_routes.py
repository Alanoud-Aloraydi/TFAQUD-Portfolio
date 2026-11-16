"""Listing the medicines, adding one, reading one."""

from flask import jsonify

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.extensions import get_clock
from app.medications.blueprint import READ_ROLES, bp
from app.medications.inputs import PlanRequest
from app.medications.plans import MedicationPlanService
from app.medications.queries import MedicationQueries
from app.medications.route_helpers import uuid_value
from app.validation import parse_json_body


@bp.get("/medication-plans")
@require_circle_role(*READ_ROLES)
def list_plans(circle_id):
    """Every medicine of the circle's patient, with its current version, any
    edit waiting to start, and its latest dose.
    """
    with transaction() as session:
        plans = MedicationQueries(session, get_clock().now()).plans(
            uuid_value(circle_id)
        )
    response = jsonify(medication_plans=plans)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/medication-plans")
@require_circle_role(CircleRole.MANAGER, area="medications")
def create_plan(circle_id):
    """Add a medicine (a manager only)."""
    body = parse_json_body(PlanRequest)
    with transaction() as session:
        plan = MedicationPlanService(
            session, get_clock().now()
        ).create(
            uuid_value(circle_id),
            uuid_value(current_auth().user_id),
            body,
        )
        result = MedicationQueries(session, get_clock().now()).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result), 201


@bp.get("/medication-plans/<plan_id>")
@require_circle_role(*READ_ROLES)
def get_plan(circle_id, plan_id):
    """One medicine of the circle's patient."""
    with transaction() as session:
        plan = MedicationQueries(session, get_clock().now()).plan(
            uuid_value(circle_id), uuid_value(plan_id)
        )
    response = jsonify(medication_plan=plan)
    response.headers["Cache-Control"] = "no-store"
    return response
