"""The account's own photo and avatar, and a member's photo."""

from flask import jsonify
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.authz.decorators import require_circle_role
from app.database import transaction
from app.errors import NotFound
from app.models import CareCircleManager
from app.photos import PhotoService
from app.photos.blueprint import MEMBERS, AvatarRequest, bp
from app.photos.route_helpers import (
    account_or_404,
    parse_uuid,
    patient_or_404,
    png_answer,
    uploaded_png,
)
from app.validation import parse_json_body


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
