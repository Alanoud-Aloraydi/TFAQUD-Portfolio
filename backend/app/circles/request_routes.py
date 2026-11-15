"""Asking a patient for a circle, listing the requests, and the
patient's answer."""

from app.auth.decorators import require_auth
from app.circles import views
from app.circles.inputs import CircleRequestInput, RespondInput
from app.circles.request_blueprint import NOT_FOUND, bp
from app.circles.support import answer, care_work, parse_id
from app.errors import NotFound
from app.models import Account
from app.push.messages import circle_request_push, request_answer_push
from app.push.notify import notify
from app.validation import parse_json_body


@bp.post("")
@require_auth
def send_request():
    """Ask a person to be the patient of a new circle.

    If an open request from the caller to the same number already exists,
    that request is returned instead of a second one.
    """
    body = parse_json_body(CircleRequestInput)
    with care_work() as work:
        row = work.care.request_creation(
            work.actor,
            body.patient_phone_number,
            body.proposed_app_mode,
        )
        view = views.sent_request_view(row)
        push = circle_request_push(work.session, row)
    # After the commit: the patient's phone, if they have the app.
    notify(push)
    return answer({"request": view}, 201)


@bp.get("")
@require_auth
def list_requests():
    """The caller's open sent requests, and requests to the caller's
    number."""
    with care_work() as work:
        account = work.session.get(Account, work.actor)
        if account is None:
            raise NotFound("This user does not exist.", code="user_not_found")
        view = views.creation_requests_view(work.session, account, work.now)
    return answer(view)


@bp.post("/<request_id>/respond")
@require_auth
def respond(request_id):
    """The patient accepts or declines; accepting does not create the
    circle."""
    body = parse_json_body(RespondInput)
    with care_work(hide_forbidden=NOT_FOUND) as work:
        row = work.care.respond_creation(
            work.actor, parse_id(request_id, "circle request"), body.accept
        )
        view = views.sent_request_view(row)
        push = request_answer_push(work.session, row)
    notify(push)
    return answer({"request": view})
