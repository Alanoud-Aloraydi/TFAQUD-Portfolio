"""The pushes of a circle request: asked, answered, and the circle ready."""

from uuid import UUID

from sqlalchemy.orm import Session

from app.circles.naming import circle_name
from app.models import CareCircle, CareCircleRequest
from app.push.messages.names import account_with_phone, display_name
from app.push.notify import Push
from app.push.sender import PushMessage
from app.push.targets import circle_target, request_target


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
        f"وصلك طلب من {requester} لمتابعة رعايتك في تفقّد."
        if requester
        else "وصلك طلب جديد لمتابعة رعايتك في تفقّد."
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
            f"تم قبول طلبك {whom}. الدائرة تجهز أول ما تكتمل البيانات.",
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
            f"«{name}» جاهزة، وتقدر تتابع الرعاية الحين.",
            "circle_ready",
            circle_target(circle.id),
        ),
    )
