"""The appointment endpoints under /api/v1/circles/<circle_id>: list, add,
change, and record how a visit went."""

from uuid import UUID

from flask import Blueprint, jsonify

from app.accounts import accounts_by_id
from app.appointments.inputs import (
    AppointmentOutcomeRequest,
    AppointmentRequest,
    AppointmentStatusRequest,
    ReviseAppointmentRequest,
)
from app.appointments.queries import (
    appointment_view,
    appointments_for_circle,
    companions_for_appointments,
    companions_for_circle,
    patient_has_account,
)
from app.appointments.service import AppointmentService
from app.appointments.visits import visit_filled
from app.auth.decorators import current_auth
from app.authz import current_circle_role, require_circle_role
from app.authz import CircleRole
from app.database import transaction
from app.errors import Forbidden, NotFound
from app.extensions import get_clock
from app.push.attention import send_all
from app.push.attention import cancelled_visit_pushes
from app.validation import parse_json_body


bp = Blueprint(
    "appointments", __name__, url_prefix="/api/v1/circles/<circle_id>"
)

MEMBERS = (
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)


def parse_uuid(value: str) -> UUID:
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
        values = appointments_for_circle(session, parse_uuid(circle_id))
    response = jsonify(appointments=values)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.get("/appointments/companions")
@require_circle_role(CircleRole.MANAGER, area="appointments")
def list_companions(circle_id):
    """List current members eligible to accompany the patient, and say
    whether the patient has a phone (the form tells who is reminded)."""
    with transaction() as session:
        circle = parse_uuid(circle_id)
        values = companions_for_circle(session, circle)
        has_account = patient_has_account(session, circle)
    response = jsonify(companions=values, patient_has_account=has_account)
    response.headers["Cache-Control"] = "no-store"
    return response


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


@bp.post("/appointments/<appointment_id>/status")
@require_circle_role(CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)
def set_appointment_status(circle_id, appointment_id):
    """Record attendance or cancellation explicitly."""
    body = parse_json_body(AppointmentStatusRequest)
    # A patient in the simplified mode says «حضرت» for their own visit, as
    # the family does; cancelling stays with those who manage appointments.
    if (
        current_circle_role() == CircleRole.SIMPLIFIED_PATIENT
        and body.status != "completed"
    ):
        raise Forbidden()
    # Change the status, then answer the appointment with its companions and
    # who made and last changed it; a cancel is told to the others.
    circle, actor = parse_uuid(circle_id), parse_uuid(current_auth().user_id)
    with transaction() as session:
        appointment = AppointmentService(
            session, get_clock().now()
        ).set_status(
            circle, parse_uuid(appointment_id), actor, body.status,
            body.expected_updated_at,
        )
        pushes = cancelled_visit_pushes(session, circle, appointment, actor)
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
    send_all(pushes)
    return jsonify(appointment=value)


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
