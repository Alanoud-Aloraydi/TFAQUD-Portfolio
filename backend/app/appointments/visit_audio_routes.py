"""A visit's voice note: read, save, remove."""

from flask import Response, jsonify, request

from app.appointments.visit_blueprint import MEMBERS, bp, parse_uuid
from app.appointments.visit_service import MAX_AUDIO_BYTES, VisitService
from app.appointments.visit_view import visit_view
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock


@bp.get("/audio")
@require_circle_role(*MEMBERS)
def get_visit_audio(circle_id, appointment_id):
    """Stream the authorized M4A note without caching it."""
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).get(
            parse_uuid(circle_id), parse_uuid(appointment_id)
        )
        if visit is None or visit.audio is None:
            raise NotFound()
        audio = bytes(visit.audio)
    response = Response(audio, mimetype="audio/mp4")
    response.headers["Cache-Control"] = "no-store"
    response.headers["Content-Disposition"] = 'inline; filename="visit.m4a"'
    return response


@bp.put("/audio")
@require_circle_role(CircleRole.MANAGER)
def save_visit_audio(circle_id, appointment_id):
    """Accept a bounded iOS M4A recording for one completed visit."""
    if request.mimetype != "audio/mp4":
        raise ValidationFailed(code="appointment_invalid_audio")
    audio = request.stream.read(MAX_AUDIO_BYTES + 1)
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).save_audio(
            parse_uuid(circle_id), parse_uuid(appointment_id),
            parse_uuid(current_auth().user_id), audio,
        )
        value = visit_view(visit)
    return jsonify(visit=value)


@bp.delete("/audio")
@require_circle_role(CircleRole.MANAGER)
def remove_visit_audio(circle_id, appointment_id):
    """Remove a voice note without deleting the visit paper."""
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).remove_audio(
            parse_uuid(circle_id), parse_uuid(appointment_id),
            parse_uuid(current_auth().user_id),
        )
        value = visit_view(visit)
    return jsonify(visit=value)
