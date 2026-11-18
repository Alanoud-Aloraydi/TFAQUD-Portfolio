"""POST /circles/self and /circles/patient-without-account: making a
circle at once."""

from app.auth.decorators import require_auth
from app.circles import views
from app.circles.blueprint import MANAGER, bp
from app.circles.inputs import CreateOfflineCircleInput, CreateSelfCircleInput
from app.circles.support import answer, care_work, save_medical
from app.push.messages.attention import send_all
from app.push.messages.superseded import superseded_pushes
from app.validation import parse_json_body


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
            body.time_zone,
        )
        save_medical(work, circle.id, body.medical_profile)
        view = views.circle_view(work.session, circle.id, work.actor, MANAGER)
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
            body.latitude,
            body.longitude,
            body.time_zone,
        )
        save_medical(work, circle.id, body.medical_profile)
        view = views.circle_view(work.session, circle.id, work.actor, MANAGER)
    return answer({"circle": view}, 201)
