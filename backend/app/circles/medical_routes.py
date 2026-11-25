"""The medical file, the emergency card and the emergency contacts (add,
change, remove)."""

from flask import Blueprint

from app.authz import require_circle_role
from app.circles.inputs import EmergencyContactInput, MedicalProfileInput
from app.circles.medical_views import (
    contact_view,
    contact_views,
    emergency_card_view,
    medical_view,
)
from app.circles.routes import MEMBER, READ_MEMBER
from app.circles.support import answer, care_work, parse_id
from app.circles.views import patient_view
from app.validation import parse_json_body

bp = Blueprint("circle_medical", __name__, url_prefix="/api/v1/circles")


@bp.get("/<circle_id>/medical-profile")
@require_circle_role(*READ_MEMBER)
def get_medical_profile(circle_id):
    """The whole medical file page: patient, health data, contacts."""
    with care_work() as work:
        patient, profile, contacts = work.medical.get_file(
            work.actor, parse_id(circle_id, "care circle")
        )
        view = {
            "patient": patient_view(work.session, patient, work.actor),
            "medical_profile": medical_view(profile),
            "emergency_contacts": contact_views(work.session, contacts),
        }
    return answer(view)


@bp.get("/<circle_id>/emergency-card")
@require_circle_role(*READ_MEMBER)
def get_emergency_card(circle_id):
    """The read-only emergency card (F18). It is built from the medical file,
    so an edit of the file shows on the card at once."""
    with care_work() as work:
        patient, profile, contacts = work.medical.get_file(
            work.actor, parse_id(circle_id, "care circle")
        )
        card = emergency_card_view(
            work.session, patient, profile, contacts
        )
    return answer({"emergency_card": card})


@bp.patch("/<circle_id>/medical-profile")
@require_circle_role(*MEMBER)
def update_medical_profile(circle_id):
    """Change only the parts that are in the body; null clears a part."""
    body = parse_json_body(MedicalProfileInput)
    with care_work() as work:
        profile = work.medical.update_profile(
            work.actor, parse_id(circle_id, "care circle"), body.to_update()
        )
        view = medical_view(profile)
    return answer({"medical_profile": view})


@bp.post("/<circle_id>/emergency-contacts")
@require_circle_role(*MEMBER)
def add_emergency_contact(circle_id):
    """Add an emergency contact to the patient's card."""
    body = parse_json_body(EmergencyContactInput)
    with care_work() as work:
        contact = work.medical.add_contact(
            work.actor,
            parse_id(circle_id, "care circle"),
            body.name,
            body.relation,
            body.relation_other,
            body.phone_number,
        )
        view = contact_view(work.session, contact)
    return answer({"emergency_contact": view}, 201)


@bp.put("/<circle_id>/emergency-contacts/<contact_id>")
@require_circle_role(*MEMBER)
def update_emergency_contact(circle_id, contact_id):
    """Change one emergency contact."""
    body = parse_json_body(EmergencyContactInput)
    with care_work() as work:
        contact = work.medical.update_contact(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(contact_id, "emergency contact"),
            body.name,
            body.relation,
            body.relation_other,
            body.phone_number,
        )
        view = contact_view(work.session, contact)
    return answer({"emergency_contact": view})


@bp.delete("/<circle_id>/emergency-contacts/<contact_id>")
@require_circle_role(*MEMBER)
def delete_emergency_contact(circle_id, contact_id):
    """Remove one emergency contact."""
    with care_work() as work:
        work.medical.delete_contact(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(contact_id, "emergency contact"),
        )
    return "", 204
