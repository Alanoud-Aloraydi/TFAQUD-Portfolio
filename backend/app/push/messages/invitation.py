"""The push for a new or resent invitation."""

from sqlalchemy.orm import Session

from app.circles.naming import circle_name
from app.models import CareCircleInvitation
from app.push.messages.names import account_with_phone, display_name
from app.push.notify import Push
from app.push.sender import PushMessage


def invitation_push(
    session: Session, invitation: CareCircleInvitation
) -> Push | None:
    """To the invited number, when it has an account: a new invitation, or
    the same one sent again."""
    invitee = account_with_phone(session, invitation.invitee_phone_number)
    if invitee is None:
        return None
    # As the invited person sees it: «دائرة» and the patient's name.
    name = circle_name(session, invitation.care_circle_id, invitee)
    inviter = display_name(session, invitation.invited_by_account_id)
    body = (
        f"وصلتك دعوة من {inviter} للانضمام إلى «{name}»."
        if inviter
        else f"وصلتك دعوة للانضمام إلى «{name}»."
    )
    return Push(
        (invitee,),
        PushMessage("دعوة لدائرة رعاية", body, "invitation"),
    )
