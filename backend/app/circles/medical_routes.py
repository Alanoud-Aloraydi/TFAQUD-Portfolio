"""The medical file and the emergency card."""

from app.authz.decorators import require_circle_role
from app.circles import views
from app.circles.blueprint import MEMBER, READ_MEMBER, bp
from app.circles.inputs import MedicalProfileInput
from app.circles.support import answer, care_work, parse_id
from app.validation import parse_json_body


@bp.get("/<circle_id>/medical-profile")
@require_circle_role(*READ_MEMBER)
def get_medical_profile(circle_id):
    """The whole medical file page: patient, health data, contacts."""
    with care_work() as work:
        patient, profile, contacts = work.medical.get_file(
            work.actor, parse_id(circle_id, "care circle")
        )
        view = {
            "patient": views.patient_view(work.session, patient, work.actor),
            "medical_profile": views.medical_view(profile),
            "emergency_contacts": views.contact_views(work.session, contacts),
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
        card = views.emergency_card_view(
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
        view = views.medical_view(profile)
    return answer({"medical_profile": view})
