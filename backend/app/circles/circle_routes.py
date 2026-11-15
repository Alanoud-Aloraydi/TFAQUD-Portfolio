"""One circle: read it, rename it, change the patient's basics, leave
it, delete it."""

from flask import request

from app.authz.decorators import current_circle_role, require_circle_role
from app.authz.roles import CircleRole
from app.circles import views
from app.circles.blueprint import MANAGER, MEMBER, READ_MEMBER, bp
from app.circles.inputs import (
    LeaveCircleInput,
    PatientUpdateInput,
    RenameCircleInput,
)
from app.circles.support import answer, care_work, parse_id
from app.validation import parse_json_body, parse_optional_json_body


@bp.get("/<circle_id>")
@require_circle_role(*READ_MEMBER)
def get_circle(circle_id):
    """One circle as its member sees it: the patient, the managers, the
    invitations, and what the asker may do.
    """
    with care_work() as work:
        view = views.circle_view(
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
        view = views.circle_view(
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
            latitude=body.latitude,
            longitude=body.longitude,
            time_zone=body.time_zone,
        )
        view = views.circle_view(
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
