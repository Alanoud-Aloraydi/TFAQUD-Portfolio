"""Authorized visit-paper text and voice endpoints."""

from uuid import UUID

from flask import Blueprint, Response, jsonify, request
from pydantic import Field

from app.appointments.visit_service import MAX_AUDIO_BYTES
from app.appointments.visit_service import VisitService, visit_view
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock
from app.validation import Dto, parse_json_body

bp = Blueprint(
    "appointment_visits", __name__,
    url_prefix=(
        "/api/v1/circles/<circle_id>/appointments/"
        "<appointment_id>/visit"
    ),
)
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.PATIENT,
    CircleRole.SIMPLIFIED_PATIENT,
)


class VisitRequest(Dto):
    """The three editable fields visible in the visit paper."""

    summary: str | None = Field(default=None, max_length=2000)
    recommendations: str | None = Field(default=None, max_length=2000)
    follow_up: str | None = Field(default=None, max_length=500)


def _uuid(value: str) -> UUID:
    """Hide malformed identifiers behind the not-found response."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None


@bp.get("")
@require_circle_role(*MEMBERS)
def get_visit(circle_id, appointment_id):
    """Return the visit paper without sending its audio in JSON."""
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).get(
            _uuid(circle_id), _uuid(appointment_id)
        )
        value = visit_view(visit)
    response = jsonify(visit=value)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.put("")
@require_circle_role(CircleRole.MANAGER)
def save_visit(circle_id, appointment_id):
    """Save the written fields for an attended appointment."""
    body = parse_json_body(VisitRequest)
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).save_text(
            _uuid(circle_id), _uuid(appointment_id),
            _uuid(current_auth().user_id), body.summary,
            body.recommendations, body.follow_up,
        )
        value = visit_view(visit)
    return jsonify(visit=value)


@bp.get("/audio")
@require_circle_role(*MEMBERS)
def get_visit_audio(circle_id, appointment_id):
    """Stream the authorized M4A note without caching it."""
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).get(
            _uuid(circle_id), _uuid(appointment_id)
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
            _uuid(circle_id), _uuid(appointment_id),
            _uuid(current_auth().user_id), audio,
        )
        value = visit_view(visit)
    return jsonify(visit=value)


@bp.delete("/audio")
@require_circle_role(CircleRole.MANAGER)
def remove_visit_audio(circle_id, appointment_id):
    """Remove a voice note without deleting the visit paper."""
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).remove_audio(
            _uuid(circle_id), _uuid(appointment_id),
            _uuid(current_auth().user_id),
        )
        value = visit_view(visit)
    return jsonify(visit=value)
