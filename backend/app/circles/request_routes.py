"""Requests to make a circle for a patient who has an account.

The person who wants to care sends a request to the patient's phone
number. The patient accepts or declines (consent). After an acceptance,
the sender completes the request into a circle, or cancels it."""

from flask import Blueprint

from app.auth.decorators import require_auth
from app.authz import CircleRole
from app.circles.circle_inputs import (
    CircleRequestInput,
    CompleteRequestInput,
    RespondInput,
)
from app.circles.request_views import creation_requests_view, sent_request_view
from app.circles.support import answer, care_work, parse_id, save_medical
from app.circles.views import circle_view
from app.errors import NotFound
from app.models import Account
from app.push.messages import (
    circle_ready_push,
    circle_request_push,
    request_answer_push,
)
from app.push.attention import send_all
from app.push.messages import superseded_pushes
from app.push.notify import notify
from app.validation import parse_json_body


bp = Blueprint(
    "creation_requests", __name__, url_prefix="/api/v1/circle-requests"
)

NOT_FOUND = "The circle request does not exist."


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
        view = sent_request_view(row)
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
        view = creation_requests_view(work.session, account, work.now)
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
        view = sent_request_view(row)
        push = request_answer_push(work.session, row)
    notify(push)
    return answer({"request": view})


@bp.post("/<request_id>/complete")
@require_auth
def complete(request_id):
    """After accepting, the patient gives the basic data. This creates it."""
    body = parse_json_body(CompleteRequestInput)
    # Make the circle, save the medical profile sent with it, and answer the
    # circle as its patient sees it.
    with care_work(hide_forbidden=NOT_FOUND) as work:
        request_uuid = parse_id(request_id, "circle request")
        circle = work.care.complete_creation(
            work.actor,
            request_uuid,
            body.birth_date,
            body.city,
            body.latitude,
            body.longitude,
            name=body.name,
            time_zone=body.time_zone,
        )
        save_medical(work, circle.id, body.medical_profile)
        mode = work.session.get(Account, work.actor).app_mode
        view = circle_view(
            work.session,
            circle.id,
            work.actor,
            (
                CircleRole.MANAGER
                if mode == "detailed"
                else CircleRole.SIMPLIFIED_PATIENT
            ),
        )
        # Tell the sender the circle is ready, after the commit.
        push = circle_ready_push(work.session, request_uuid, circle)
        # The other requests sent to this number close: their senders hear.
        closed = superseded_pushes(
            work.session, work.care.superseded_requests
        )
    notify(push)
    send_all(closed)
    return answer({"circle": view, "account_app_mode": mode}, 201)


@bp.delete("/<request_id>")
@require_auth
def cancel(request_id):
    """The sender or the patient cancels a request that is not finished."""
    with care_work(hide_forbidden=NOT_FOUND) as work:
        work.care.cancel_creation(
            work.actor, parse_id(request_id, "circle request")
        )
    return "", 204
