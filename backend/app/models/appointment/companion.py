"""The `appointment_companion` table."""

from uuid import UUID

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class AppointmentCompanion(db.Model):
    """One circle member selected for an appointment. The server requires
    one at least on every save; a companion's row goes with their deleted
    account, and the appointment stays (migrations 0029, 0044)."""

    __tablename__ = "appointment_companion"

    appointment_id: Mapped[UUID] = mapped_column(
        ForeignKey("appointment.id", ondelete="CASCADE"),
        primary_key=True,
    )
    # Goes with a deleted account; the appointment stays (migration 0029).
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"),
        primary_key=True,
        index=True,
    )
