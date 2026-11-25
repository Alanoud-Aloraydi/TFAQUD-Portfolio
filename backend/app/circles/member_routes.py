"""The circle's people: the leader's endpoints for the members (what each
edits, the lead, removing one), and the invitations to manage the circle
(invite, send again, withdraw)."""

from flask import Blueprint

from app.authz import require_circle_role
from app.circles.circle_inputs import (
    InviteInput,
    LeaderInput,
    MemberAccessInput,
)
from app.circles.routes import MANAGER
from app.circles.support import answer, care_work, parse_id
from app.circles.views import circle_view, invitation_view
from app.push.messages import invitation_push
from app.push.notify import notify
from app.validation import parse_json_body

bp = Blueprint("circle_members", __name__, url_prefix="/api/v1/circles")


@bp.patch("/<circle_id>/members/<account_id>")
@require_circle_role(MANAGER)
def update_member_access(circle_id, account_id):
    """Let another member edit the medicines, the measurements and the
    appointments, or not; only the circle's leader (`app.circles.leader`).
    """
    body = parse_json_body(MemberAccessInput)
    with care_work() as work:
        cid = parse_id(circle_id, "care circle")
        work.care.update_member_access(
            work.actor,
            cid,
            parse_id(account_id, "account"),
            body.areas(),
        )
        view = circle_view(work.session, cid, work.actor, MANAGER)
    return answer({"circle": view})


@bp.put("/<circle_id>/leader")
@require_circle_role(MANAGER)
def hand_over_leadership(circle_id):
    """The leader hands the circle to another member; a patient in the
    detailed mode always leads their own (409 `patient_leads`)."""
    body = parse_json_body(LeaderInput)
    with care_work() as work:
        cid = parse_id(circle_id, "care circle")
        work.care.hand_over_leadership(work.actor, cid, body.account_id)
        view = circle_view(work.session, cid, work.actor, MANAGER)
    return answer({"circle": view})


@bp.delete("/<circle_id>/members/<account_id>")
@require_circle_role(MANAGER)
def remove_member(circle_id, account_id):
    """Remove another member; only the circle's leader."""
    with care_work() as work:
        work.care.remove_member(
            work.actor,
            parse_id(circle_id, "care circle"),
            parse_id(account_id, "account"),
        )
    return "", 204


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
        view = invitation_view(invitation)
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
        view = invitation_view(invitation)
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
