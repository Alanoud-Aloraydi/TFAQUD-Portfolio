"""Invitations: as the circle's managers see them, and as the invited
person sees theirs."""

from sqlalchemy import select
from sqlalchemy.orm import Session, aliased

from app.circles import naming
from app.circles.views.times import iso_time
from app.models import Account, CareCircle, CareCircleInvitation


def invitation_view(invitation: CareCircleInvitation) -> dict:
    """An invitation as the managers of the circle see it."""
    return {
        "id": str(invitation.id),
        "invitee_phone_number": invitation.invitee_phone_number,
        "status": invitation.status,
        "created_at": iso_time(invitation.created_at),
        "last_sent_at": iso_time(invitation.last_sent_at),
    }


def received_invitations_view(
    session: Session, account: Account
) -> list[dict]:
    """Pending invitations addressed to this account's phone number."""
    invitation = CareCircleInvitation
    inviter = aliased(Account)
    patient_account = aliased(Account)
    rows = session.execute(
        select(
            invitation,
            CareCircle.name,
            inviter.display_name,
            inviter.avatar_code,
            CareCircle.account_id,
            CareCircle.first_name,
            patient_account.display_name.label("patient_display_name"),
            patient_account.first_name.label("patient_account_first_name"),
        )
        .join(CareCircle, CareCircle.id == invitation.care_circle_id)
        .outerjoin(inviter, inviter.id == invitation.invited_by_account_id)
        .outerjoin(
            patient_account, patient_account.id == CareCircle.account_id
        )
        .where(
            invitation.invitee_phone_number == account.phone_number,
            invitation.status == "pending",
        )
        .order_by(invitation.created_at.desc(), invitation.id)
    ).all()
    return [
        {
            "id": str(row[0].id),
            # As the invited person will see it: «دائرة» and the patient's
            # name, never the patient's own choice.
            "circle_name": naming.name_for(
                account.id,
                own_name=row.name,
                patient_account_id=row.account_id,
                patient_account_name=(
                    row.patient_display_name or row.patient_account_first_name
                ),
                patient_first_name=row.first_name,
            ),
            "invited_by": (
                {
                    "display_name": row.display_name,
                    "avatar_code": row.avatar_code,
                }
                if row.display_name
                else None
            ),
            "created_at": iso_time(row[0].created_at),
            "last_sent_at": iso_time(row[0].last_sent_at),
        }
        for row in rows
    ]
