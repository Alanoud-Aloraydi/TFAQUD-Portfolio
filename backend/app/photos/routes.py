"""The photo endpoints: what they share (ids, the PNG sent, the image
answered, whose photo it is), and the account's own photo and avatar, and
a member's photo."""

from uuid import UUID

from flask import Blueprint, Response, jsonify, request
from pydantic import field_validator
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.authz import CircleRole, current_circle_role, require_circle_role
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.models import Account, CareCircle, CareCircleManager, MedicationPlan
from app.photos.service import AVATAR_CODES, MAX_PHOTO_BYTES, PhotoService
from app.validation import Dto, parse_json_body


bp = Blueprint("photos", __name__, url_prefix="/api/v1")

MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)

PATIENT_WRITERS = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


class AvatarRequest(Dto):
    """One selected local avatar asset."""

    avatar_code: str

    @field_validator("avatar_code")
    @classmethod
    def valid_code(cls, value: str) -> str:
        """Accept only an avatar the app offers."""
        if value not in AVATAR_CODES:
            raise ValueError("Unknown avatar code.")
        return value


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


@bp.get("/accounts/me/photo")
@require_auth
def my_photo():
    """Read the authenticated account's private image."""
    with transaction() as session:
        photo = PhotoService(session).get(
            "account", parse_uuid(current_auth().user_id)
        )
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return png_answer(data)


@bp.put("/accounts/me/photo")
@require_auth
def save_my_photo():
    """Save a cropped profile photo and clear any avatar selection."""
    data = uploaded_png()
    with transaction() as session:
        account_id = parse_uuid(current_auth().user_id)
        PhotoService(session).put("account", account_id, data)
        account_or_404(session, account_id).avatar_code = None
    return jsonify(saved=True)


@bp.put("/accounts/me/avatar")
@require_auth
def save_my_avatar():
    """Choose an avatar in place of the account photo."""
    body = parse_json_body(AvatarRequest)
    with transaction() as session:
        account_id = parse_uuid(current_auth().user_id)
        PhotoService(session).delete("account", account_id)
        account_or_404(session, account_id).avatar_code = body.avatar_code
    return jsonify(avatar_code=body.avatar_code)


@bp.delete("/accounts/me/avatar")
@require_auth
def clear_my_avatar():
    """Restore the account's initial-letter appearance."""
    with transaction() as session:
        account_id = parse_uuid(current_auth().user_id)
        PhotoService(session).delete("account", account_id)
        account_or_404(session, account_id).avatar_code = None
    return jsonify(avatar_code=None)


@bp.get("/circles/<circle_id>/members/<account_id>/photo")
@require_circle_role(*MEMBERS)
def member_photo(circle_id, account_id):
    """Read only a current member's account photo."""
    # Only a member of this circle (a manager, or its patient) has a picture to
    # see here.
    circle = parse_uuid(circle_id)
    member = parse_uuid(account_id)
    with transaction() as session:
        current = session.scalar(select(CareCircleManager.id).where(
            CareCircleManager.care_circle_id == circle,
            CareCircleManager.account_id == member,
        ))
        patient = patient_or_404(session, circle)
        if current is None and patient.account_id != member:
            raise NotFound()
        photo = PhotoService(session).get("account", member)
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return png_answer(data)
