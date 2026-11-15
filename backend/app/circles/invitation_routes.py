"""A circle's invitations: invite, send again, withdraw."""

from app.authz.decorators import require_circle_role
from app.circles import views
from app.circles.blueprint import MANAGER, bp
from app.circles.inputs import InviteInput
from app.circles.support import answer, care_work, parse_id
from app.push.messages import invitation_push
from app.push.notify import notify
from app.validation import parse_json_body


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
        push = invitation_push(work.session, invitation)
    # After the commit: the invited person's phone, if they have the app.
    notify(push)
    return answer({"invitation": view}, 201)


@bp.post("/<circle_id>/invitations/<invitation_id>/resend")
@require_circle_role(MANAGER)
def resend_invitation(circle_id, invitation_id):
    """Send a pending invitation again."""
    with care_work() as work:
        invitation = work.care.resend_invitation(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(invitation_id, "invitation"),
        )
        view = views.invitation_view(invitation)
        push = invitation_push(work.session, invitation)
    notify(push)
    return answer({"invitation": view})


@bp.delete("/<circle_id>/invitations/<invitation_id>")
@require_circle_role(MANAGER)
def cancel_invitation(circle_id, invitation_id):
    """Withdraw a pending invitation."""
    with care_work() as work:
        work.care.cancel_invitation(
            work.actor,
            parse_id(invitation_id, "invitation"),
            circle_id=parse_id(circle_id, "care circle"),
        )
    return "", 204
