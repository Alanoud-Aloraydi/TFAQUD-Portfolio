"""Requests to create a circle for a patient who has an account.

The person who wants to care sends a request to the patient's phone number.
The patient accepts or declines (consent). After accepting, the patient
completes the basic data, and only then is the circle created.
"""

from flask import Blueprint

from app.auth.decorators import require_auth
from app.authz.roles import CircleRole
from app.circles import views
from app.circles.inputs import (
    CompleteRequestInput,
    CreationRequestInput,
    RespondInput,
)
from app.circles.support import answer, care_work, parse_id, save_medical
from app.errors import NotFound
from app.models import Account
from app.validation import parse_json_body

bp = Blueprint(
    "creation_requests", __name__, url_prefix="/api/v1/circle-requests"
)

_NOT_FOUND = "The circle request does not exist."


@bp.post("")
@require_auth
def send_request():
    """Ask a person to be the patient of a new circle.

    If an open request from you to the same number already exists, that
    request is returned instead of a second one.
    """
    body = parse_json_body(CreationRequestInput)
    with care_work() as work:
        row = work.care.request_creation(
            work.actor,
            body.patient_phone_number,
            body.circle_label,
            body.proposed_app_mode,
        )
        view = views.sent_request_view(row)
    return answer({"request": view}, 201)


@bp.get("")
@require_auth
def list_requests():
    """Requests you sent (open ones) and requests addressed to your number."""
    with care_work() as work:
        account = work.session.get(Account, work.actor)
        if account is None:
            raise NotFound("This user does not exist.", code="user_not_found")
        view = views.creation_requests_view(work.session, account, work.now)
    return answer(view)


@bp.post("/<request_id>/respond")
@require_auth
def respond(request_id):
    """The patient accepts or declines. Accepting does not create the circle."""
    body = parse_json_body(RespondInput)
    with care_work(hide_forbidden=_NOT_FOUND) as work:
        row = work.care.respond_creation(
            work.actor, parse_id(request_id, "circle request"), body.accept
        )
        view = views.sent_request_view(row)
    return answer({"request": view})


@bp.post("/<request_id>/complete")
@require_auth
def complete(request_id):
    """After accepting, the patient gives the basic data. This creates it."""
    body = parse_json_body(CompleteRequestInput)
    with care_work(hide_forbidden=_NOT_FOUND) as work:
        circle = work.care.complete_creation(
            work.actor,
            parse_id(request_id, "circle request"),
            body.birth_date,
            body.city,
            body.latitude,
            body.longitude,
        )
        save_medical(work, circle.id, body.medical_profile)
        mode = work.session.get(Account, work.actor).app_mode
        view = views.circle_view(
            work.session,
            circle.id,
            work.actor,
            (
                CircleRole.MANAGER
                if mode == "detailed"
                else CircleRole.SIMPLIFIED_PATIENT
            ),
        )
    return answer({"circle": view}, 201)


@bp.delete("/<request_id>")
@require_auth
def cancel(request_id):
    """The sender or the patient cancels a request that is not finished."""
    with care_work(hide_forbidden=_NOT_FOUND) as work:
        work.care.cancel_creation(
            work.actor, parse_id(request_id, "circle request")
        )
    return "", 204
