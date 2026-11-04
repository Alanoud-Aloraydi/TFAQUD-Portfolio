"""The pushes that mirror the app's notifications page.

Each one is built inside the request's transaction, from the rows it just
changed, and sent after the commit with `notify`. The words are Arabic, as
the app is. They do not guess anyone's gender.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import (
    Account,
    CareCircle,
    CareCircleCreationRequest,
    CareCircleManagerInvitation,
)
from app.push.notify import Push
from app.push.sender import PushMessage


def _account_with_phone(session: Session, phone: str) -> UUID | None:
    return session.scalar(
        select(Account.id).where(Account.phone_number == phone)
    )


def _display_name(session: Session, account_id: UUID | None) -> str | None:
    if account_id is None:
        return None
    account = session.get(Account, account_id)
    if account is None:
        return None
    return account.display_name or account.first_name


def invitation_push(
    session: Session, invitation: CareCircleManagerInvitation
) -> Push | None:
    """To the invited number, when it has an account: a new invitation, or
    the same one sent again."""
    invitee = _account_with_phone(session, invitation.invitee_phone_number)
    if invitee is None:
        return None
    circle = session.get(CareCircle, invitation.care_circle_id)
    circle_name = circle.name if circle else ""
    inviter = _display_name(session, invitation.invited_by_account_id)
    body = (
        f"دعوة من {inviter} للانضمام إلى دائرة «{circle_name}»."
        if inviter
        else f"دعوة للانضمام إلى دائرة «{circle_name}»."
    )
    return Push(
        (invitee,),
        PushMessage("دعوة إلى دائرة رعاية", body, "invitation"),
    )


def circle_request_push(
    session: Session, request: CareCircleCreationRequest
) -> Push | None:
    """To the patient's number, when it has an account: someone asks to
    care for them."""
    patient = _account_with_phone(session, request.patient_phone_number)
    if patient is None:
        return None
    requester = _display_name(session, request.requested_by_account_id)
    body = (
        f"طلب من {requester} لمتابعة رعايتك في تفقّد."
        if requester
        else "طلب جديد لمتابعة رعايتك في تفقّد."
    )
    return Push((patient,), PushMessage("طلب رعاية", body, "circle_request"))


def request_answer_push(request: CareCircleCreationRequest) -> Push | None:
    """To the person who asked: the patient accepted or declined."""
    label = request.proposed_circle_label
    if request.status == "accepted":
        message = PushMessage(
            "تمت الموافقة على طلبك",
            f"تمت الموافقة على طلبك لرعاية «{label}». تُنشأ الدائرة بعد "
            "إكمال البيانات.",
            "request_answer",
        )
    elif request.status == "declined":
        message = PushMessage(
            "اعتذار عن طلب الرعاية",
            f"لم تتم الموافقة على طلبك لرعاية «{label}».",
            "request_answer",
        )
    else:
        return None
    return Push((request.requested_by_account_id,), message)


def circle_ready_push(
    session: Session, request_id: UUID, circle: CareCircle
) -> Push | None:
    """To the person who asked: the patient finished, the circle exists."""
    request = session.get(CareCircleCreationRequest, request_id)
    if request is None:
        return None
    return Push(
        (request.requested_by_account_id,),
        PushMessage(
            "الدائرة جاهزة",
            f"أُنشئت دائرة «{circle.name}»، ويمكنك متابعة الرعاية الآن.",
            "circle_ready",
        ),
    )
