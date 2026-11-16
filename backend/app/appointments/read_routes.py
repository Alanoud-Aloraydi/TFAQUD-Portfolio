"""Listing the appointments and the members who may go with the patient."""

from flask import jsonify

from app.appointments.blueprint import MEMBERS, bp, parse_uuid
from app.appointments.companions import companions_for_circle
from app.appointments.queries import appointments_for_circle
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction


@bp.get("/appointments")
@require_circle_role(*MEMBERS)
def list_appointments(circle_id):
    """List the selected circle's planned and historical visits."""
    with transaction() as session:
        values = appointments_for_circle(session, parse_uuid(circle_id))
    response = jsonify(appointments=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/appointments/companions")
@require_circle_role(CircleRole.MANAGER, area="appointments")
def list_companions(circle_id):
    """List current members eligible to accompany the patient."""
    with transaction() as session:
        values = companions_for_circle(session, parse_uuid(circle_id))
    response = jsonify(companions=values)
    response.headers["Cache-Control"] = "no-store"
    return response
