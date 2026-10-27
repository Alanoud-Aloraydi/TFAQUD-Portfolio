"""Invitations that other people sent to this account's phone number.

Managers send and cancel invitations under their circle
(see app/circles/routes.py). This module is the invited person's side.
"""

from flask import Blueprint

from app.auth.decorators import require_auth
from app.circles import views
from app.circles.inputs import RespondInput
from app.circles.support import answer, care_work, parse_id
from app.errors import NotFound
from app.models import Account
from app.validation import parse_json_body

bp = Blueprint("invitations", __name__, url_prefix="/api/v1/invitations")

_NOT_FOUND = "The invitation does not exist."


@bp.get("")
@require_auth
def list_invitations():
    """Pending invitations to manage a circle, sent to your number."""
    with care_work() as work:
        account = work.session.get(Account, work.actor)
        if account is None:
            raise NotFound("This user does not exist.", code="user_not_found")
        view = views.received_invitations_view(work.session, account)
    return answer({"invitations": view})


@bp.post("/<invitation_id>/respond")
@require_auth
def respond(invitation_id):
    """Accept (you become a manager of the circle) or decline."""
    body = parse_json_body(RespondInput)
    with care_work(hide_forbidden=_NOT_FOUND) as work:
        row = work.care.respond_invitation(
            work.actor, parse_id(invitation_id, "invitation"), body.accept
        )
        view = {
            "id": str(row.id),
            "status": row.status,
            "care_circle_id": (
                str(row.care_circle_id) if row.status == "accepted" else None
            ),
        }
    return answer({"invitation": view})
