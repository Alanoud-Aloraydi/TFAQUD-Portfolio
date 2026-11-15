"""The emergency contacts: add, change, remove."""

from app.authz.decorators import require_circle_role
from app.circles import views
from app.circles.blueprint import MEMBER, bp
from app.circles.inputs import EmergencyContactInput
from app.circles.support import answer, care_work, parse_id
from app.validation import parse_json_body


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
            body.phone_number,
        )
        view = views.contact_view(work.session, contact)
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
            body.phone_number,
        )
        view = views.contact_view(work.session, contact)
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
