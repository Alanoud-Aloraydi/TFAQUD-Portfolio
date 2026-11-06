"""Authorized appointment transport endpoints."""

from uuid import UUID

from flask import Blueprint, jsonify

from app.appointments.inputs import AppointmentRequest
from app.appointments.inputs import AppointmentStatusRequest
from app.appointments.inputs import ReviseAppointmentRequest
from app.appointments.queries import appointment_view, appointments_for_circle
from app.appointments.queries import companions_for_appointments
from app.appointments.queries import companions_for_circle
from app.appointments.service import AppointmentService
from app.accounts import accounts_by_id
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound
from app.extensions import get_clock
from app.validation import parse_json_body

bp = Blueprint(
    "appointments", __name__, url_prefix="/api/v1/circles/<circle_id>"
)
MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.PATIENT,
    CircleRole.SIMPLIFIED_PATIENT,
)


def _uuid(value: str) -> UUID:
    """Parse an opaque identifier as a not-found response."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        raise NotFound() from None


@bp.get("/appointments")
@require_circle_role(*MEMBERS)
def list_appointments(circle_id):
    """List the selected circle's planned and historical visits."""
    with transaction() as session:
        values = appointments_for_circle(session, _uuid(circle_id))
    response = jsonify(appointments=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/appointments/companions")
@require_circle_role(CircleRole.MANAGER)
def list_companions(circle_id):
    """List current members eligible to accompany the patient."""
    with transaction() as session:
        values = companions_for_circle(session, _uuid(circle_id))
    response = jsonify(companions=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.post("/appointments")
@require_circle_role(CircleRole.MANAGER)
def create_appointment(circle_id):
    """Save one appointment."""
    body = parse_json_body(AppointmentRequest)
    with transaction() as session:
        appointment = AppointmentService(
            session, get_clock().now()
        ).create(_uuid(circle_id), _uuid(current_auth().user_id), body)
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
    return jsonify(appointment=value), 201


@bp.put("/appointments/<appointment_id>")
@require_circle_role(CircleRole.MANAGER)
def revise_appointment(circle_id, appointment_id):
    """Change a scheduled appointment."""
    body = parse_json_body(ReviseAppointmentRequest)
    with transaction() as session:
        appointment = AppointmentService(
            session, get_clock().now()
        ).revise(
            _uuid(circle_id), _uuid(appointment_id),
            _uuid(current_auth().user_id), body,
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


@bp.post("/appointments/<appointment_id>/status")
@require_circle_role(CircleRole.MANAGER)
def set_appointment_status(circle_id, appointment_id):
    """Record attendance or cancellation explicitly."""
    body = parse_json_body(AppointmentStatusRequest)
    with transaction() as session:
        appointment = AppointmentService(
            session, get_clock().now()
        ).set_status(
            _uuid(circle_id), _uuid(appointment_id),
            _uuid(current_auth().user_id), body.status,
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
        )
    return jsonify(appointment=value)
