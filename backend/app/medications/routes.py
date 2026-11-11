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
from app.medications.inputs import CancelPendingRequest, DoseRecordRequest
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

_READ_ROLES = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)
_RECORD_ROLES = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


@bp.get("/medication-plans")
@require_circle_role(*_READ_ROLES)
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
@require_circle_role(CircleRole.MANAGER)
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
@require_circle_role(*_READ_ROLES)
def get_plan(circle_id, plan_id):
    """One medicine of the circle's patient."""
    with transaction() as session:
        plan = MedicationQueries(session, get_clock().now()).plan(
            uuid_value(circle_id), uuid_value(plan_id)
        )
    response = jsonify(medication_plan=plan)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.put("/medication-plans/<plan_id>")
@require_circle_role(CircleRole.MANAGER)
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
@require_circle_role(CircleRole.MANAGER)
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
@require_circle_role(CircleRole.MANAGER)
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


@bp.get("/medication-occurrences")
@require_circle_role(*_READ_ROLES)
def list_occurrences(circle_id):
    """The doses due between two dates (at most 32 days), each with its record
    when there is one.
    """
    query = occurrence_query()
    plan_id = uuid_value(query.plan_id) if query.plan_id else None
    with transaction() as session:
        occurrences = MedicationQueries(
            session, get_clock().now()
        ).occurrences(
            uuid_value(circle_id),
            query.from_date,
            query.to_date,
            plan_id,
        )
    response = jsonify(medication_occurrences=occurrences)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.put("/medication-dose-records/<schedule_id>/<scheduled_on>")
@require_circle_role(*_RECORD_ROLES)
def record_dose(circle_id, schedule_id, scheduled_on):
    """Record one dose as taken or skipped. Sending the same record again
    changes nothing; a different one for a dose already recorded is a conflict.
    """
    # A date that cannot be read names no dose.
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
        result = dose_record_response(session, record)
    return jsonify(medication_dose_record=result)
