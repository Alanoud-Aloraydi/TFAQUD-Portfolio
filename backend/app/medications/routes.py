"""Authorized medication plan and dose-record endpoints."""

from datetime import date

from flask import Blueprint, jsonify

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound
from app.extensions import get_clock
from app.medications.doses import MedicationDoseService
from app.medications.inputs import DoseRecordRequest
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plans import MedicationPlanService
from app.medications.queries import MedicationQueries
from app.medications.route_helpers import dose_record_response
from app.medications.route_helpers import occurrence_query, uuid_value
from app.validation import parse_json_body

bp = Blueprint(
    "medications",
    __name__,
    url_prefix="/api/v1/circles/<circle_id>",
)

_MEMBER_ROLES = (
    CircleRole.MANAGER,
    CircleRole.PATIENT,
    CircleRole.SIMPLIFIED_PATIENT,
)


@bp.get("/medication-plans")
@require_circle_role(*_MEMBER_ROLES)
def list_plans(circle_id):
    with transaction() as session:
        plans = MedicationQueries(session).plans(uuid_value(circle_id))
    response = jsonify(medication_plans=plans)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/medication-plans")
@require_circle_role(CircleRole.MANAGER)
def create_plan(circle_id):
    body = parse_json_body(PlanRequest)
    with transaction() as session:
        plan = MedicationPlanService(
            session, get_clock().now()
        ).create(
            uuid_value(circle_id),
            uuid_value(current_auth().user_id),
            body,
        )
        result = MedicationQueries(session).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result), 201


@bp.get("/medication-plans/<plan_id>")
@require_circle_role(*_MEMBER_ROLES)
def get_plan(circle_id, plan_id):
    with transaction() as session:
        plan = MedicationQueries(session).plan(
            uuid_value(circle_id), uuid_value(plan_id)
        )
    response = jsonify(medication_plan=plan)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.put("/medication-plans/<plan_id>")
@require_circle_role(CircleRole.MANAGER)
def revise_plan(circle_id, plan_id):
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
        result = MedicationQueries(session).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result)


@bp.post("/medication-plans/<plan_id>/discontinue")
@require_circle_role(CircleRole.MANAGER)
def discontinue_plan(circle_id, plan_id):
    with transaction() as session:
        plan = MedicationPlanService(
            session, get_clock().now()
        ).discontinue(
            uuid_value(circle_id),
            uuid_value(plan_id),
            uuid_value(current_auth().user_id),
        )
        result = MedicationQueries(session).plan(
            uuid_value(circle_id), plan.id
        )
    return jsonify(medication_plan=result)


@bp.get("/medication-occurrences")
@require_circle_role(*_MEMBER_ROLES)
def list_occurrences(circle_id):
    query = occurrence_query()
    plan_id = uuid_value(query.plan_id) if query.plan_id else None
    with transaction() as session:
        occurrences = MedicationQueries(session).occurrences(
            uuid_value(circle_id),
            query.from_date,
            query.to_date,
            plan_id,
        )
    response = jsonify(medication_occurrences=occurrences)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.put("/medication-dose-records/<schedule_id>/<scheduled_on>")
@require_circle_role(*_MEMBER_ROLES)
def record_dose(circle_id, schedule_id, scheduled_on):
    try:
        dose_date = date.fromisoformat(scheduled_on)
    except (TypeError, ValueError):
        raise NotFound() from None
    body = parse_json_body(DoseRecordRequest)
    with transaction() as session:
        record = MedicationDoseService(
            session, get_clock().now()
        ).record(
            uuid_value(circle_id),
            uuid_value(schedule_id),
            dose_date,
            uuid_value(current_auth().user_id),
            body,
        )
        result = dose_record_response(record)
    return jsonify(medication_dose_record=result)
