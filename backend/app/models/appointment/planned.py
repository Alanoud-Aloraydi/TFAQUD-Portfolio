"""The `appointment` table."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    SmallInteger,
    Text,
    Time,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.appointment.appointment_rules import APPOINTMENT_TABLE_ARGS


class Appointment(db.Model):
    """A single planned visit with an explicit attendance outcome."""

    __tablename__ = "appointment"
    __table_args__ = APPOINTMENT_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    # Visits booked together (migration 0058) share this; null for a visit
    # on its own. It ties them for the words «الزيارة 2 من 6» and nothing
    # else: an edit to one never reaches the others.
    series_id: Mapped[UUID | None] = mapped_column(index=True)
    # The clinic or doctor, as typed; null when not given.
    specialty: Mapped[str | None] = mapped_column(Text)
    kind: Mapped[str] = mapped_column(Text)
    # The words of «أخرى»; null for every other kind.
    other_text: Mapped[str | None] = mapped_column(Text)
    scheduled_on: Mapped[date] = mapped_column(Date)
    time_of_day: Mapped[time] = mapped_column(Time)
    place: Mapped[str | None] = mapped_column(Text)
    remote_method: Mapped[str | None] = mapped_column(Text)
    # How long before its time the visit's own reminder comes, in minutes
    # (migration 0061). The day-before reminder is separate and always
    # set; this is the near one, which used to be a fixed two hours for
    # every visit. 60 for the visits saved before the choice existed.
    reminder_lead_minutes: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, server_default=text("60")
    )
    status: Mapped[str] = mapped_column(
        Text, server_default=text("'scheduled'")
    )
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    # Who last edited it or set its status (migration 0027); empty until
    # then.
    updated_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
