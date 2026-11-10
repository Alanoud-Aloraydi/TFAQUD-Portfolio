"""Authorized photo and avatar endpoints for care-circle identities."""

from uuid import UUID

from flask import Blueprint, Response, jsonify, request
from pydantic import field_validator
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.authz.decorators import current_circle_role, require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.models import Account, CareCircleManager, MedicationPlan
from app.models import Patient
from app.photos import AVATAR_CODES, MAX_PHOTO_BYTES, PhotoService
from app.validation import Dto, parse_json_body

bp = Blueprint("photos", __name__, url_prefix="/api/v1")
MEMBERS = (CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)


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


def _uuid(value: str) -> UUID:
    """An id from the URL; 404 when it is not a UUID."""
    try:
        return UUID(value)
    except (TypeError, ValueError, AttributeError):
        raise NotFound() from None


def _png() -> bytes:
    """The uploaded PNG's bytes, read one byte past the limit so a larger file
    is caught; 422 for another type.
    """
    if request.mimetype != "image/png":
        raise ValidationFailed(code="invalid_photo")
    return request.stream.read(MAX_PHOTO_BYTES + 1)


def _image(data: bytes) -> Response:
    """Answer a PNG that no cache keeps."""
    response = Response(data, mimetype="image/png")
    response.headers["Cache-Control"] = "private, no-store"
    return response


def _account(session, account_id: UUID) -> Account:
    """The account; 404 when there is none."""
    account = session.get(Account, account_id)
    if account is None:
        raise NotFound()
    return account


def _patient(session, circle_id: UUID) -> Patient:
    """The circle's patient; 404 when there is none."""
    patient = session.scalar(select(Patient).where(
        Patient.care_circle_id == circle_id
    ))
    if patient is None:
        raise NotFound()
    return patient


def _patient_write(session, circle_id: UUID) -> Patient:
    """Allow the patient themself, or a manager of a patient without an
    account. A patient with an account in the circle (any app mode) chooses
    their own picture: nobody else can change it."""
    patient = _patient(session, circle_id)
    viewer = _uuid(current_auth().user_id)
    if patient.account_id == viewer:
        return patient
    if (current_circle_role() == CircleRole.MANAGER
            and patient.account_id is None):
        return patient
    raise NotFound()


def _patient_photo_owner(patient: Patient) -> tuple[str, UUID]:
    """A patient with an account shares the account's own photo and avatar
    (one person, one picture); a patient without one keeps their own."""
    if patient.account_id is not None:
        return "account", patient.account_id
    return "patient", patient.id


@bp.get("/accounts/me/photo")
@require_auth
def my_photo():
    """Read the authenticated account's private image."""
    with transaction() as session:
        photo = PhotoService(session).get(
            "account", _uuid(current_auth().user_id)
        )
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return _image(data)


@bp.put("/accounts/me/photo")
@require_auth
def save_my_photo():
    """Save a cropped profile photo and clear any avatar selection."""
    data = _png()
    with transaction() as session:
        account_id = _uuid(current_auth().user_id)
        PhotoService(session).put("account", account_id, data)
        _account(session, account_id).avatar_code = None
    return jsonify(saved=True)


@bp.put("/accounts/me/avatar")
@require_auth
def save_my_avatar():
    """Choose an avatar in place of the account photo."""
    body = parse_json_body(AvatarRequest)
    with transaction() as session:
        account_id = _uuid(current_auth().user_id)
        PhotoService(session).delete("account", account_id)
        _account(session, account_id).avatar_code = body.avatar_code
    return jsonify(avatar_code=body.avatar_code)


@bp.delete("/accounts/me/avatar")
@require_auth
def clear_my_avatar():
    """Restore the account's initial-letter appearance."""
    with transaction() as session:
        account_id = _uuid(current_auth().user_id)
        PhotoService(session).delete("account", account_id)
        _account(session, account_id).avatar_code = None
    return jsonify(avatar_code=None)


@bp.get("/circles/<circle_id>/members/<account_id>/photo")
@require_circle_role(*MEMBERS)
def member_photo(circle_id, account_id):
    """Read only a current member's account photo."""
    # Only a member of this circle (a manager, or its patient) has a picture to
    # see here.
    circle = _uuid(circle_id)
    member = _uuid(account_id)
    with transaction() as session:
        current = session.scalar(select(CareCircleManager.id).where(
            CareCircleManager.care_circle_id == circle,
            CareCircleManager.account_id == member,
        ))
        patient = _patient(session, circle)
        if current is None and patient.account_id != member:
            raise NotFound()
        photo = PhotoService(session).get("account", member)
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return _image(data)


@bp.get("/circles/<circle_id>/patient/photo")
@require_circle_role(*MEMBERS)
def patient_photo(circle_id):
    """Read the selected circle's patient portrait."""
    with transaction() as session:
        patient = _patient(session, _uuid(circle_id))
        photo = PhotoService(session).get(*_patient_photo_owner(patient))
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return _image(data)


@bp.put("/circles/<circle_id>/patient/photo")
@require_circle_role(*MEMBERS)
def save_patient_photo(circle_id):
    """Let the patient, or the manager of a patient without an account,
    save a photo."""
    data = _png()
    with transaction() as session:
        patient = _patient_write(session, _uuid(circle_id))
        kind, owner_id = _patient_photo_owner(patient)
        PhotoService(session).put(kind, owner_id, data)
        if kind == "account":
            _account(session, owner_id).avatar_code = None
        else:
            patient.avatar_code = None
    return jsonify(saved=True)


@bp.put("/circles/<circle_id>/patient/avatar")
@require_circle_role(*MEMBERS)
def save_patient_avatar(circle_id):
    """Choose a character for the patient."""
    body = parse_json_body(AvatarRequest)
    with transaction() as session:
        patient = _patient_write(session, _uuid(circle_id))
        kind, owner_id = _patient_photo_owner(patient)
        PhotoService(session).delete(kind, owner_id)
        if kind == "account":
            _account(session, owner_id).avatar_code = body.avatar_code
        else:
            patient.avatar_code = body.avatar_code
    return jsonify(avatar_code=body.avatar_code)


@bp.delete("/circles/<circle_id>/patient/avatar")
@require_circle_role(*MEMBERS)
def clear_patient_avatar(circle_id):
    """Restore the patient's initial-letter appearance."""
    with transaction() as session:
        patient = _patient_write(session, _uuid(circle_id))
        kind, owner_id = _patient_photo_owner(patient)
        PhotoService(session).delete(kind, owner_id)
        if kind == "account":
            _account(session, owner_id).avatar_code = None
        else:
            patient.avatar_code = None
    return jsonify(avatar_code=None)


def _plan(session, circle_id: UUID, plan_id: UUID) -> MedicationPlan:
    """The circle's medicine with this id; 404 for another circle's."""
    plan = session.scalar(select(MedicationPlan).join(
        Patient, Patient.id == MedicationPlan.patient_id
    ).where(
        MedicationPlan.id == plan_id,
        Patient.care_circle_id == circle_id,
    ))
    if plan is None:
        raise NotFound()
    return plan


@bp.get("/circles/<circle_id>/medication-plans/<plan_id>/photo")
@require_circle_role(*MEMBERS)
def medication_photo(circle_id, plan_id):
    """Read a medication photo only inside its care circle."""
    with transaction() as session:
        plan = _plan(session, _uuid(circle_id), _uuid(plan_id))
        photo = PhotoService(session).get("medication", plan.id)
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return _image(data)


@bp.put("/circles/<circle_id>/medication-plans/<plan_id>/photo")
@require_circle_role(CircleRole.MANAGER)
def save_medication_photo(circle_id, plan_id):
    """Save a plan-level photo shared by its versions."""
    data = _png()
    with transaction() as session:
        plan = _plan(session, _uuid(circle_id), _uuid(plan_id))
        PhotoService(session).put("medication", plan.id, data)
    return jsonify(saved=True)


@bp.delete("/circles/<circle_id>/medication-plans/<plan_id>/photo")
@require_circle_role(CircleRole.MANAGER)
def remove_medication_photo(circle_id, plan_id):
    """Remove the photo without changing medication history."""
    with transaction() as session:
        plan = _plan(session, _uuid(circle_id), _uuid(plan_id))
        PhotoService(session).delete("medication", plan.id)
    return jsonify(saved=True)
