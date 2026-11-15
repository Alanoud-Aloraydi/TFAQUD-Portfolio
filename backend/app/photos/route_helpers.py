"""What the photo endpoints share: ids, the PNG sent, the image answered,
and whose photo it is."""

from uuid import UUID

from flask import Response, request
from sqlalchemy import select

from app.auth.decorators import current_auth
from app.authz.decorators import current_circle_role
from app.authz.roles import CircleRole
from app.errors import NotFound, ValidationFailed
from app.models import Account, CareCircle, MedicationPlan
from app.photos import MAX_PHOTO_BYTES


def parse_uuid(value: str) -> UUID:
    """An id from the URL; 404 when it is not a UUID."""
    try:
        return UUID(value)
    except (TypeError, ValueError, AttributeError):
        raise NotFound() from None


def uploaded_png() -> bytes:
    """The uploaded PNG's bytes, read one byte past the limit so a larger file
    is caught; 422 for another type.
    """
    if request.mimetype != "image/png":
        raise ValidationFailed(code="invalid_photo")
    return request.stream.read(MAX_PHOTO_BYTES + 1)


def png_answer(data: bytes) -> Response:
    """Answer a PNG that no cache keeps."""
    response = Response(data, mimetype="image/png")
    response.headers["Cache-Control"] = "private, no-store"
    return response


def account_or_404(session, account_id: UUID) -> Account:
    """The account; 404 when there is none."""
    account = session.get(Account, account_id)
    if account is None:
        raise NotFound()
    return account


def patient_or_404(session, circle_id: UUID) -> CareCircle:
    """The circle (its patient); 404 when there is none."""
    patient = session.get(CareCircle, circle_id)
    if patient is None:
        raise NotFound()
    return patient


def require_patient_write(session, circle_id: UUID) -> CareCircle:
    """Allow the patient themself, or a manager of a patient without an
    account. A patient with an account in the circle (any app mode) chooses
    their own picture: nobody else can change it."""
    patient = patient_or_404(session, circle_id)
    viewer = parse_uuid(current_auth().user_id)
    if patient.account_id == viewer:
        return patient
    if (current_circle_role() == CircleRole.MANAGER
            and patient.account_id is None):
        return patient
    raise NotFound()


def patient_photo_owner(patient: CareCircle) -> tuple[str, UUID]:
    """A patient with an account shares the account's own photo and avatar
    (one person, one picture); a patient without one keeps their own."""
    if patient.account_id is not None:
        return "account", patient.account_id
    return "patient", patient.id


def plan_or_404(session, circle_id: UUID, plan_id: UUID) -> MedicationPlan:
    """The circle's medicine with this id; 404 for another circle's."""
    plan = session.scalar(select(MedicationPlan).where(
        MedicationPlan.id == plan_id,
        MedicationPlan.care_circle_id == circle_id,
    ))
    if plan is None:
        raise NotFound()
    return plan
