"""The photos of a circle: the patient's portrait and avatar, and a
medicine's photo."""

from flask import Blueprint, jsonify

from app.authz import CircleRole, require_circle_role
from app.database import transaction
from app.errors import NotFound
from app.photos.routes import (
    AvatarRequest,
    MEMBERS,
    PATIENT_WRITERS,
    account_or_404,
    parse_uuid,
    patient_or_404,
    patient_photo_owner,
    plan_or_404,
    png_answer,
    require_patient_write,
    uploaded_png,
)
from app.photos.service import PhotoService
from app.validation import parse_json_body

bp = Blueprint("circle_photos", __name__, url_prefix="/api/v1")


@bp.get("/circles/<circle_id>/patient/photo")
@require_circle_role(*MEMBERS)
def patient_photo(circle_id):
    """Read the selected circle's patient portrait."""
    with transaction() as session:
        patient = patient_or_404(session, parse_uuid(circle_id))
        photo = PhotoService(session).get(*patient_photo_owner(patient))
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return png_answer(data)


@bp.put("/circles/<circle_id>/patient/photo")
@require_circle_role(*PATIENT_WRITERS)
def save_patient_photo(circle_id):
    """Let the patient, or the manager of a patient without an account,
    save a photo."""
    data = uploaded_png()
    with transaction() as session:
        patient = require_patient_write(session, parse_uuid(circle_id))
        kind, owner_id = patient_photo_owner(patient)
        PhotoService(session).put(kind, owner_id, data)
        if kind == "account":
            account_or_404(session, owner_id).avatar_code = None
        else:
            patient.avatar_code = None
    return jsonify(saved=True)


@bp.put("/circles/<circle_id>/patient/avatar")
@require_circle_role(*PATIENT_WRITERS)
def save_patient_avatar(circle_id):
    """Choose a character for the patient."""
    body = parse_json_body(AvatarRequest)
    with transaction() as session:
        patient = require_patient_write(session, parse_uuid(circle_id))
        kind, owner_id = patient_photo_owner(patient)
        PhotoService(session).delete(kind, owner_id)
        if kind == "account":
            account_or_404(session, owner_id).avatar_code = body.avatar_code
        else:
            patient.avatar_code = body.avatar_code
    return jsonify(avatar_code=body.avatar_code)


@bp.delete("/circles/<circle_id>/patient/avatar")
@require_circle_role(*PATIENT_WRITERS)
def clear_patient_avatar(circle_id):
    """Restore the patient's initial-letter appearance."""
    with transaction() as session:
        patient = require_patient_write(session, parse_uuid(circle_id))
        kind, owner_id = patient_photo_owner(patient)
        PhotoService(session).delete(kind, owner_id)
        if kind == "account":
            account_or_404(session, owner_id).avatar_code = None
        else:
            patient.avatar_code = None
    return jsonify(avatar_code=None)


@bp.get("/circles/<circle_id>/medication-plans/<plan_id>/photo")
@require_circle_role(*MEMBERS)
def medication_photo(circle_id, plan_id):
    """Read a medication photo only inside its care circle."""
    with transaction() as session:
        plan = plan_or_404(session, parse_uuid(circle_id), parse_uuid(plan_id))
        photo = PhotoService(session).get("medication", plan.id)
        if photo is None:
            raise NotFound()
        data = bytes(photo.data)
    return png_answer(data)


@bp.put("/circles/<circle_id>/medication-plans/<plan_id>/photo")
@require_circle_role(CircleRole.MANAGER, area="medications")
def save_medication_photo(circle_id, plan_id):
    """Save a plan-level photo shared by its versions."""
    data = uploaded_png()
    with transaction() as session:
        plan = plan_or_404(session, parse_uuid(circle_id), parse_uuid(plan_id))
        PhotoService(session).put("medication", plan.id, data)
    return jsonify(saved=True)


@bp.delete("/circles/<circle_id>/medication-plans/<plan_id>/photo")
@require_circle_role(CircleRole.MANAGER, area="medications")
def remove_medication_photo(circle_id, plan_id):
    """Remove the photo without changing medication history."""
    with transaction() as session:
        plan = plan_or_404(session, parse_uuid(circle_id), parse_uuid(plan_id))
        PhotoService(session).delete("medication", plan.id)
    return jsonify(saved=True)
