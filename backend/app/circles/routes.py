"""Care circles: create, read, rename, leave, delete; the patient's data;
invitations to manage a circle; the medical file and emergency contacts.

Every route with a circle id in its URL is protected by
`require_circle_role`. A caller who is not in the circle, and a circle that
does not exist, both get the same 403 (see app/authz/decorators.py).
"""

from flask import Blueprint, request

from app.auth.decorators import require_auth
from app.authz.decorators import current_circle_role, require_circle_role
from app.authz.roles import CircleRole
from app.circles import views
from app.circles.inputs import (
    CreateOfflineCircleInput,
    CreateSelfCircleInput,
    EmergencyContactInput,
    InviteInput,
    LeaveCircleInput,
    MedicalProfileInput,
    PatientUpdateInput,
    RenameCircleInput,
)
from app.circles.support import answer, care_work, parse_id, save_medical
from app.validation import parse_json_body, parse_optional_json_body

bp = Blueprint("circles", __name__, url_prefix="/api/v1/circles")

MANAGER = CircleRole.MANAGER
# A patient with a linked account can read and edit their own data.
MEMBER = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


# ---- create ---------------------------------------------------------


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
            body.latitude,
            body.longitude,
        )
        save_medical(work, circle.id, body.medical_profile)
        view = views.circle_view(work.session, circle.id, work.actor, MANAGER)
    return answer({"circle": view}, 201)


@bp.post("/patient-without-account")
@require_auth
def create_offline_circle():
    """Care for a patient who has no account; the caller manages it."""
    body = parse_json_body(CreateOfflineCircleInput)
    with care_work() as work:
        circle = work.care.create_without_account(
            work.actor,
            body.name,
            body.patient_first_name,
            body.patient_last_name,
            body.birth_date,
            body.city,
            body.latitude,
            body.longitude,
        )
        save_medical(work, circle.id, body.medical_profile)
        view = views.circle_view(work.session, circle.id, work.actor, MANAGER)
    return answer({"circle": view}, 201)


# ---- read and change the circle --------------------------------------


@bp.get("/<circle_id>")
@require_circle_role(*MEMBER)
def get_circle(circle_id):
    with care_work() as work:
        view = views.circle_view(
            work.session,
            parse_id(circle_id, "care circle"),
            work.actor,
            current_circle_role(),
        )
    return answer({"circle": view})


@bp.patch("/<circle_id>")
@require_circle_role(MANAGER)
def rename_circle(circle_id):
    body = parse_json_body(RenameCircleInput)
    with care_work() as work:
        cid = parse_id(circle_id, "care circle")
        work.care.rename_circle(work.actor, cid, body.name)
        view = views.circle_view(work.session, cid, work.actor, MANAGER)
    return answer({"circle": view})


@bp.put("/<circle_id>/patient")
@require_circle_role(*MEMBER)
def update_patient(circle_id):
    """Birth date, city, location; names too when the patient has no account."""
    body = parse_json_body(PatientUpdateInput)
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
        )
        view = views.circle_view(
            work.session, cid, work.actor, current_circle_role()
        )
    return answer({"circle": view})


@bp.post("/<circle_id>/leave")
@require_circle_role(MANAGER)
def leave_circle(circle_id):
    """Leave as a manager. The last manager must confirm deleting the circle."""
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


# ---- invitations to manage this circle ----------------------------------


@bp.post("/<circle_id>/invitations")
@require_circle_role(MANAGER)
def invite_manager(circle_id):
    """Invite a phone number. An open invitation to it is sent again."""
    body = parse_json_body(InviteInput)
    with care_work() as work:
        invitation = work.care.invite_manager(
            work.actor,
            parse_id(circle_id, "care circle"),
            body.invitee_phone_number,
        )
        view = views.invitation_view(invitation)
    return answer({"invitation": view}, 201)


@bp.post("/<circle_id>/invitations/<invitation_id>/resend")
@require_circle_role(MANAGER)
def resend_invitation(circle_id, invitation_id):
    with care_work() as work:
        invitation = work.care.resend_invitation(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(invitation_id, "invitation"),
        )
        view = views.invitation_view(invitation)
    return answer({"invitation": view})


@bp.delete("/<circle_id>/invitations/<invitation_id>")
@require_circle_role(MANAGER)
def cancel_invitation(circle_id, invitation_id):
    with care_work() as work:
        work.care.cancel_invitation(
            work.actor,
            parse_id(invitation_id, "invitation"),
            circle_id=parse_id(circle_id, "care circle"),
        )
    return "", 204


# ---- medical file --------------------------------------------------------


@bp.get("/<circle_id>/medical-profile")
@require_circle_role(*MEMBER)
def get_medical_profile(circle_id):
    """The whole medical file page: patient, health data, contacts."""
    with care_work() as work:
        patient, profile, contacts = work.medical.get_file(
            work.actor, parse_id(circle_id, "care circle")
        )
        view = {
            "patient": views.patient_view(work.session, patient, work.actor),
            "medical_profile": views.medical_view(profile),
            "emergency_contacts": [views.contact_view(c) for c in contacts],
        }
    return answer(view)


@bp.patch("/<circle_id>/medical-profile")
@require_circle_role(*MEMBER)
def update_medical_profile(circle_id):
    """Change only the parts that are in the body; null clears a part."""
    body = parse_json_body(MedicalProfileInput)
    with care_work() as work:
        profile = work.medical.update_profile(
            work.actor, parse_id(circle_id, "care circle"), body.to_update()
        )
        view = views.medical_view(profile)
    return answer({"medical_profile": view})


@bp.post("/<circle_id>/emergency-contacts")
@require_circle_role(*MEMBER)
def add_emergency_contact(circle_id):
    body = parse_json_body(EmergencyContactInput)
    with care_work() as work:
        contact = work.medical.add_contact(
            work.actor,
            parse_id(circle_id, "care circle"),
            body.name,
            body.relation,
            body.phone_number,
        )
        view = views.contact_view(contact)
    return answer({"emergency_contact": view}, 201)


@bp.put("/<circle_id>/emergency-contacts/<contact_id>")
@require_circle_role(*MEMBER)
def update_emergency_contact(circle_id, contact_id):
    body = parse_json_body(EmergencyContactInput)
    with care_work() as work:
        contact = work.medical.update_contact(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(contact_id, "emergency contact"),
            body.name,
            body.relation,
            body.phone_number,
        )
        view = views.contact_view(contact)
    return answer({"emergency_contact": view})


@bp.delete("/<circle_id>/emergency-contacts/<contact_id>")
@require_circle_role(*MEMBER)
def delete_emergency_contact(circle_id, contact_id):
    with care_work() as work:
        work.medical.delete_contact(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(contact_id, "emergency contact"),
        )
    return "", 204
