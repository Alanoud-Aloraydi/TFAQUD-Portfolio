"""Authorized visit-paper text and voice endpoints: the text here, the
voice note in visit_audio_routes.py, which joins the blueprint when
imported here."""

from flask import jsonify

from app.appointments import visit_audio_routes
from app.appointments.visit_blueprint import (
    MEMBERS,
    VisitRequest,
    bp,
    parse_uuid,
)
from app.appointments.visit_service import VisitService
from app.appointments.visit_view import visit_view
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.extensions import get_clock
from app.validation import parse_json_body


@bp.get("")
@require_circle_role(*MEMBERS)
def get_visit(circle_id, appointment_id):
    """Return the visit paper without sending its audio in JSON."""
    with transaction() as session:
        visit = VisitService(session, get_clock().now()).get(
            parse_uuid(circle_id), parse_uuid(appointment_id)
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
            parse_uuid(circle_id), parse_uuid(appointment_id),
            parse_uuid(current_auth().user_id), body.summary,
            body.recommendations, body.follow_up,
        )
        value = visit_view(visit)
    return jsonify(visit=value)


__all__ = ["bp", "get_visit", "save_visit", "visit_audio_routes"]
