"""Finishing an accepted request into a circle, or cancelling one."""

from app.auth.decorators import require_auth
from app.authz.roles import CircleRole
from app.circles import views
from app.circles.inputs import CompleteRequestInput
from app.circles.request_blueprint import NOT_FOUND, bp
from app.circles.support import answer, care_work, parse_id, save_medical
from app.models import Account
from app.push.messages import circle_ready_push
from app.push.notify import notify
from app.validation import parse_json_body


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
        # Tell the sender the circle is ready, after the commit.
        push = circle_ready_push(work.session, request_uuid, circle)
    notify(push)
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
