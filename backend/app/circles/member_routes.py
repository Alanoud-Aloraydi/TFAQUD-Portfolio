"""The leader's endpoints for the members: what each edits, the lead,
removing one."""

from app.authz.decorators import require_circle_role
from app.circles import views
from app.circles.blueprint import MANAGER, bp
from app.circles.inputs import LeaderInput, MemberAccessInput
from app.circles.support import answer, care_work, parse_id
from app.validation import parse_json_body


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
        view = views.circle_view(work.session, cid, work.actor, MANAGER)
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
        view = views.circle_view(work.session, cid, work.actor, MANAGER)
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
