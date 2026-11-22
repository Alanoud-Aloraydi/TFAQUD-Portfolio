"""Changing how a visit went, from «السجل» (appointment_outcomes.py)."""

from flask import jsonify

from app.accounts import accounts_by_id
from app.appointments.blueprint import bp, parse_uuid
from app.appointments.companions import companions_for_appointments
from app.appointments.inputs import AppointmentOutcomeRequest
from app.appointments.queries import appointment_view
from app.appointments.service import AppointmentService
from app.appointments.visit_fill import visit_filled
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.extensions import get_clock
from app.validation import parse_json_body


@bp.post("/appointments/<appointment_id>/outcome")
@require_circle_role(CircleRole.MANAGER, area="appointments")
def change_appointment_outcome(circle_id, appointment_id):
    """Keep the outcome chosen for a visit, and answer the visit as it is
    now, with its companions and who made and last changed it."""
    body = parse_json_body(AppointmentOutcomeRequest)
    circle, actor = parse_uuid(circle_id), parse_uuid(current_auth().user_id)
    with transaction() as session:
        appointment = AppointmentService(
            session, get_clock().now()
        ).change_outcome(
            circle, parse_uuid(appointment_id), actor, body.status,
            body.expected_updated_at,
        )
        accounts = accounts_by_id(
            session,
            {
                account_id
                for account_id in (
                    appointment.created_by_account_id,
                    appointment.updated_by_account_id,
                )
                if account_id is not None
            },
        )
        value = appointment_view(
            appointment,
            companions_for_appointments(session, [appointment.id])[
                appointment.id
            ],
            accounts,
            visit_filled(session, appointment.id),
        )
    return jsonify(appointment=value)
