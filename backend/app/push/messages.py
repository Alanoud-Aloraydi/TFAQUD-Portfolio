"""The pushes that mirror the app's notifications page: an invitation sent
or resent, a circle request asked, answered or ready, and a request that
can no longer be accepted.

Each one is built inside the request's transaction, from the rows it just
changed, and sent after the commit with `notify`."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.circles.naming import circle_name
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleRequest,
)
from app.push.notify import (
    Push,
    circle_target,
    invitation_target,
    request_target,
)
from app.push.sender import PushMessage


def account_with_phone(session: Session, phone: str) -> UUID | None:
    """The id of the account that signs in with `phone`, or None."""
    return session.scalar(
        select(Account.id).where(Account.phone_number == phone)
    )


def display_name(session: Session, account_id: UUID | None) -> str | None:
    """The name to show for an account: its display name, else its first name;
    None when there is no such account.
    """
    if account_id is None:
        return None
    account = session.get(Account, account_id)
    if account is None:
        return None
    return account.display_name or account.first_name


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
        PushMessage(
            "دعوة لدائرة رعاية",
            body,
            "invitation",
            invitation_target(invitation.id),
        ),
    )


def circle_request_push(
    session: Session, request: CareCircleRequest
) -> Push | None:
    """To the patient's number, when it has an account: someone asks to
    care for them."""
    patient = account_with_phone(session, request.patient_phone_number)
    if patient is None:
        return None
    requester = display_name(session, request.requested_by_account_id)
    body = (
        f"وصلك طلب من {requester} لمتابعة رعايتك في تفقُد."
        if requester
        else "وصلك طلب جديد لمتابعة رعايتك في تفقُد."
    )
    message = PushMessage(
        "طلب رعاية جديد", body, "circle_request", request_target(request.id)
    )
    return Push((patient,), message)


def request_answer_push(
    session: Session, request: CareCircleRequest
) -> Push | None:
    """To the person who asked: the patient accepted or declined. The
    patient answered, so their name can be told. A declined request is
    on the bell («السابقة»), so its push names it; an accepted one has no
    card there while it waits for the patient."""
    # The patient's name when the number has an account (the sender knows it).
    patient = display_name(
        session, account_with_phone(session, request.patient_phone_number)
    )
    whom = f"لرعاية {patient}" if patient else "للرعاية"
    # Only an answer is announced: accepted or declined.
    if request.status == "accepted":
        message = PushMessage(
            "تم قبول طلبك",
            f"تم قبول طلبك {whom}. تجهز الدائرة فور اكتمال البيانات.",
            "request_answer",
        )
    elif request.status == "declined":
        message = PushMessage(
            "تم الاعتذار عن طلبك",
            f"تم الاعتذار عن طلبك {whom}.",
            "request_answer",
            request_target(request.id),
        )
    else:
        return None
    return Push((request.requested_by_account_id,), message)


def circle_ready_push(
    session: Session, request_id: UUID, circle: CareCircle
) -> Push | None:
    """To the person who asked: the patient finished, the circle exists."""
    request = session.get(CareCircleRequest, request_id)
    if request is None:
        return None
    # As the sender sees it: «دائرة» and the patient's name, not the
    # patient's own choice.
    name = circle_name(session, circle.id, request.requested_by_account_id)
    return Push(
        (request.requested_by_account_id,),
        PushMessage(
            "الدائرة جاهزة",
            f"«{name}» جاهزة، ويمكنك متابعة الرعاية الآن.",
            "circle_ready",
            circle_target(circle.id),
        ),
    )


TITLE = "لا يمكن قبول طلبك"


def superseded_text(patient: str | None) -> str:
    """«لا يمكن قبول طلبك لرعاية خالد، لأن هذا الرقم أصبحت له دائرة رعاية
    في تفقُد.»: «له» is the number's, so the words fit a man or a woman."""
    whom = f"لرعاية {patient}" if patient else "للرعاية"
    return (
        f"لا يمكن قبول طلبك {whom}، لأن هذا الرقم أصبحت له دائرة رعاية "
        "في تفقُد."
    )


def superseded_pushes(session: Session, request_ids) -> list[Push]:
    """One push to the sender of each request the new circle closed."""
    pushes = []
    for request_id in request_ids:
        request = session.get(CareCircleRequest, request_id)
        if request is None:
            continue
        patient = display_name(
            session, account_with_phone(session, request.patient_phone_number)
        )
        message = PushMessage(
            TITLE, superseded_text(patient), "request_superseded",
            request_target(request.id),
        )
        pushes.append(Push((request.requested_by_account_id,), message))
    return pushes
