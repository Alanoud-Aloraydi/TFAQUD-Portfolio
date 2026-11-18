"""The push to the person who asked: their request can no longer be
accepted, because the patient has a circle now (they made their own, or
finished another request). Nothing to answer: it only tells, and the
request stays in «السابقة» with the same reason."""

from sqlalchemy.orm import Session

from app.models import CareCircleRequest
from app.push.messages.names import account_with_phone, display_name
from app.push.notify import Push
from app.push.sender import PushMessage
from app.push.targets import request_target

TITLE = "طلبك ما يمكن قبوله"


def superseded_text(patient: str | None) -> str:
    """«ما يمكن قبول طلبك لرعاية خالد، لأن هذا الرقم صار له دائرة رعاية
    في تفقّد.»: «له» is the number's, so the words fit a man or a woman."""
    whom = f"لرعاية {patient}" if patient else "للرعاية"
    return (
        f"ما يمكن قبول طلبك {whom}، لأن هذا الرقم صار له دائرة رعاية "
        "في تفقّد."
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
