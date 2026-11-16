"""Adding an appointment and changing it."""

from flask import jsonify

from app.accounts import accounts_by_id
from app.appointments.blueprint import bp, parse_uuid
from app.appointments.companions import companions_for_appointments
from app.appointments.inputs import (
    AppointmentRequest,
    ReviseAppointmentRequest,
)
from app.appointments.queries import appointment_view
from app.appointments.service import AppointmentService
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.extensions import get_clock
from app.validation import parse_json_body


@bp.post("/appointments")
@require_circle_role(CircleRole.MANAGER, area="appointments")
def create_appointment(circle_id):
    """Save a booking: one appointment, or one per date of a series."""
    body = parse_json_body(AppointmentRequest)
    # Save them, then answer with their companions and who made them. The
    # first is answered as `appointment`, as it always was; a series
    # answers every visit it made in `appointments`, oldest first.
    with transaction() as session:
        saved = AppointmentService(session, get_clock().now()).create(
            parse_uuid(circle_id), parse_uuid(current_auth().user_id), body
        )
        accounts = accounts_by_id(
            session,
            {
                account_id
                for appointment in saved
                for account_id in (
                    appointment.created_by_account_id,
                    appointment.updated_by_account_id,
                )
                if account_id is not None
            },
        )
        companions = companions_for_appointments(
            session, [appointment.id for appointment in saved]
        )
        values = [
            appointment_view(
                appointment, companions[appointment.id], accounts
            )
            for appointment in saved
        ]
    return jsonify(appointment=values[0], appointments=values), 201


@bp.put("/appointments/<appointment_id>")
@require_circle_role(CircleRole.MANAGER, area="appointments")
def revise_appointment(circle_id, appointment_id):
    """Change a scheduled appointment."""
    body = parse_json_body(ReviseAppointmentRequest)
    # Save the edit, then answer the appointment with its companions and who
    # made and last changed it.
    with transaction() as session:
        appointment = AppointmentService(
            session, get_clock().now()
        ).revise(
            parse_uuid(circle_id), parse_uuid(appointment_id),
            parse_uuid(current_auth().user_id), body,
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
        )
    return jsonify(appointment=value)
