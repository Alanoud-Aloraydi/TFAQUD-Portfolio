"""The circle endpoints under /api/v1/circles: make a circle, read it,
rename it, change the patient's basics, leave it, delete it.

Every route with a circle id in its URL is protected by
`require_circle_role`. A caller who is not in the circle, and a circle that
does not exist, both get the same 403 (see app.authz)."""

from flask import Blueprint, request

from app.auth.decorators import require_auth
from app.authz import CircleRole, current_circle_role, require_circle_role
from app.circles.circle_inputs import (
    CreateOfflineCircleInput,
    CreateSelfCircleInput,
    LeaveCircleInput,
    PatientUpdateInput,
    RenameCircleInput,
)
from app.circles.support import answer, care_work, parse_id, save_medical
from app.circles.views import circle_view
from app.push.attention import send_all
from app.push.messages import superseded_pushes
from app.validation import parse_json_body, parse_optional_json_body


bp = Blueprint("circles", __name__, url_prefix="/api/v1/circles")

MANAGER = CircleRole.MANAGER

# A patient with a linked account can read and edit their own data.
MEMBER = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)

READ_MEMBER = (*MEMBER, CircleRole.MEMBER)


@bp.get("/<circle_id>")
@require_circle_role(*READ_MEMBER)
def get_circle(circle_id):
    """One circle as its member sees it: the patient, the managers, the
    invitations, and what the asker may do.
    """
    with care_work() as work:
        view = circle_view(
            work.session,
            parse_id(circle_id, "care circle"),
            work.actor,
            current_circle_role(),
        )
    return answer({"circle": view})


@bp.patch("/<circle_id>")
@require_circle_role(*MEMBER)
def rename_circle(circle_id):
    """The patient's own name for their circle. Only the patient with an
    account names it; the others see «دائرة» and the patient's name."""
    body = parse_json_body(RenameCircleInput)
    with care_work() as work:
        cid = parse_id(circle_id, "care circle")
        work.care.rename_circle(work.actor, cid, body.name)
        view = circle_view(
            work.session, cid, work.actor, current_circle_role()
        )
    return answer({"circle": view})


@bp.put("/<circle_id>/patient")
@require_circle_role(*MEMBER)
def update_patient(circle_id):
    """Birth date, city, zone, location; the names too when the patient
    has no account."""
    body = parse_json_body(PatientUpdateInput)
    # Save the details, and answer the circle as the asker sees it.
    with care_work() as work:
        cid = parse_id(circle_id, "care circle")
        work.care.update_patient_profile(
            work.actor,
            cid,
            body.birth_date,
            body.city,
            first_name=body.first_name,
            last_name=body.last_name,
            time_zone=body.time_zone,
        )
        view = circle_view(
            work.session, cid, work.actor, current_circle_role()
        )
    return answer({"circle": view})


@bp.post("/<circle_id>/leave")
@require_circle_role(MANAGER, CircleRole.MEMBER)
def leave_circle(circle_id):
    """Leave the circle, also as a member whose editing is paused; the
    patient or the last manager must confirm deleting the circle."""
    body = parse_optional_json_body(LeaveCircleInput)
    with care_work() as work:
        work.care.leave_circle(
            work.actor,
            parse_id(circle_id, "care circle"),
            confirm_delete=body.confirm_delete,
        )
    return "", 204


@bp.delete("/<circle_id>")
@require_circle_role(*MEMBER)
def delete_circle(circle_id):
    """Delete the circle: ?confirm=true is required (it cannot be undone)."""
    confirm = request.args.get("confirm", "").lower() == "true"
    with care_work() as work:
        work.care.delete_circle(
            work.actor, parse_id(circle_id, "care circle"), confirm=confirm
        )
    return "", 204


@bp.post("/self")
@require_auth
def create_self_circle():
    """Self-care: the account is both the patient and the manager."""
    body = parse_json_body(CreateSelfCircleInput)
    with care_work() as work:
        circle = work.care.create_self(
            work.actor,
            body.name,
            body.birth_date,
            body.city,
            body.time_zone,
        )
        save_medical(work, circle.id, body.medical_profile)
        view = circle_view(work.session, circle.id, work.actor, MANAGER)
        # Requests sent to this number close: each sender is told.
        pushes = superseded_pushes(
            work.session, work.care.superseded_requests
        )
    send_all(pushes)
    return answer({"circle": view}, 201)


@bp.post("/patient-without-account")
@require_auth
def create_offline_circle():
    """Care for a patient who has no account; the caller manages it."""
    body = parse_json_body(CreateOfflineCircleInput)
    with care_work() as work:
        circle = work.care.create_without_account(
            work.actor,
            body.patient_first_name,
            body.patient_last_name,
            body.birth_date,
            body.city,
            body.time_zone,
        )
        save_medical(work, circle.id, body.medical_profile)
        view = circle_view(work.session, circle.id, work.actor, MANAGER)
    return answer({"circle": view}, 201)
