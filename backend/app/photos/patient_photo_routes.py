"""The patient's portrait and avatar."""

from flask import jsonify

from app.authz.decorators import require_circle_role
from app.database import transaction
from app.errors import NotFound
from app.photos import PhotoService
from app.photos.blueprint import MEMBERS, PATIENT_WRITERS, AvatarRequest, bp
from app.photos.route_helpers import (
    account_or_404,
    parse_uuid,
    patient_or_404,
    patient_photo_owner,
    png_answer,
    require_patient_write,
    uploaded_png,
)
from app.validation import parse_json_body


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
