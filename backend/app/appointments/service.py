"""Transactional appointment creation, revision, and outcomes."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.appointments.appointment_booking import AppointmentBooking
from app.appointments.appointment_companions import AppointmentCompanions
from app.appointments.appointment_fields import AppointmentFields
from app.appointments.appointment_outcomes import AppointmentOutcomes
from app.appointments.appointment_reads import AppointmentReads
from app.appointments.appointment_writes import AppointmentWrites


class AppointmentService(
    AppointmentBooking,
    AppointmentWrites,
    AppointmentOutcomes,
    AppointmentReads,
    AppointmentCompanions,
    AppointmentFields,
):
    """Keep appointment writes within one authorized circle."""

    def __init__(self, session: Session, now: datetime):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now
