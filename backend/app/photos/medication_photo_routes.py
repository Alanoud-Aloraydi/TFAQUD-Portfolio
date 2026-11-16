"""A medicine's photo: read, save, remove."""

from flask import jsonify

from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound
from app.photos import PhotoService
from app.photos.blueprint import MEMBERS, bp
from app.photos.route_helpers import (
    parse_uuid,
    plan_or_404,
    png_answer,
    uploaded_png,
)


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
