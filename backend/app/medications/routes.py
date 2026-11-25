"""The medicine endpoints under /api/v1/circles/<circle_id>: list the
medicines, add one, read one, edit it, stop it, cancel an edit not
started; and what every medicine endpoint shares."""

from uuid import UUID

from flask import Blueprint, jsonify, request
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.accounts import recorder_response
from app.auth.decorators import current_auth
from app.authz import CircleRole, require_circle_role
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock
from app.medications.dose_inputs import OccurrenceQuery
from app.medications.inputs import (
    CancelPendingRequest,
    PlanRequest,
    RevisePlanRequest,
)
from app.medications.plans import MedicationPlanService
from app.medications.queries import MedicationQueries
from app.models import Account
from app.validation import parse_json_body


bp = Blueprint(
    "medications",
    __name__,
    url_prefix="/api/v1/circles/<circle_id>",
)

READ_ROLES = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)

RECORD_ROLES = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


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
    # Who recorded it (null when their account was deleted).
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
