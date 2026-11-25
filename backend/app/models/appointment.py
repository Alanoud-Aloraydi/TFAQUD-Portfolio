"""Appointments: the `appointment` table with its kinds and rules, who
goes with the patient (`appointment_companion`), and the visit paper
(`appointment_visit`)."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    LargeBinary,
    SmallInteger,
    Text,
    Time,
    false,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


APPOINTMENT_KINDS: tuple[str, ...] = (
    # Seeing the doctor.
    "follow_up", "new_visit", "remote", "emergency",
    # Checks.
    "test", "imaging", "eye_exam", "hearing_test",
    # Treatment and procedures.
    "surgery", "physio", "dialysis", "therapy_session", "dressing",
    # Prevention and routine care.
    "vaccine", "checkup", "dental", "pharmacy",
    # Sessions.
    "mental", "speech",
    # Typed by the person, in other_text.
    "other",
)


def kinds_sql() -> str:
    """The constraint's list: «'follow_up', 'new_visit', …»."""
    return ", ".join(f"'{kind}'" for kind in APPOINTMENT_KINDS)


# What each kind is called, as the app names it («appointments.kinds»), so
# a push says which visit it is about.
KIND_NAMES: dict[str, str] = {
    "follow_up": "مراجعة", "new_visit": "كشف جديد",
    "remote": "استشارة عن بُعد", "emergency": "طوارئ", "test": "تحليل",
    "imaging": "أشعة", "eye_exam": "فحص نظر", "hearing_test": "فحص سمع",
    "surgery": "عملية", "physio": "علاج طبيعي", "dialysis": "غسيل كلى",
    "therapy_session": "جلسة علاج", "dressing": "تغيير ضماد أو إبرة",
    "vaccine": "تطعيم", "checkup": "فحص دوري", "dental": "أسنان",
    "pharmacy": "صرف أدوية", "mental": "جلسة نفسية",
    "speech": "جلسة نطق وتخاطب",
}


def visit_name(kind: str, other_text: str | None) -> str | None:
    """«غسيل كلى»; for «أخرى», what the person typed; None when unknown."""
    if kind == "other":
        return (other_text or "").strip() or None
    return KIND_NAMES.get(kind)


APPOINTMENT_TABLE_ARGS = (
    CheckConstraint(
        f"kind IN ({kinds_sql()})",
        name="kind",
    ),
    CheckConstraint(
        "(kind = 'other' AND other_text IS NOT NULL AND "
        "length(btrim(other_text)) > 0 AND "
        "char_length(other_text) <= 80) OR "
        "(kind <> 'other' AND other_text IS NULL)",
        name="other_text",
    ),
    CheckConstraint(
        "status IN ('scheduled', 'completed', 'cancelled')",
        name="status",
    ),
    # «فائت» chosen from «السجل» leaves a visit open.
    CheckConstraint(
        "NOT marked_missed OR status = 'scheduled'",
        name="marked_missed",
    ),
    CheckConstraint(
        "(kind = 'remote' AND remote_method IS NOT NULL "
        "AND remote_method IN ('video', 'phone') "
        "AND place IS NULL) OR (kind <> 'remote' AND "
        "remote_method IS NULL AND place IS NOT NULL AND "
        "length(btrim(place)) > 0)",
        name="location_shape",
    ),
    CheckConstraint(
        "specialty IS NULL OR (length(btrim(specialty)) > 0 AND "
        "char_length(specialty) <= 80)",
        name="specialty",
    ),
    CheckConstraint(
        "place IS NULL OR char_length(place) <= 160",
        name="place_length",
    ),
    Index(
        "ix_appointment_care_circle_id_scheduled_on_time_of_day",
        "care_circle_id", "scheduled_on", "time_of_day",
    ),
)


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
    # Visits booked together share this; null for a visit
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
    # How long before its time the visit's own reminder comes, in minutes.
    # The day-before reminder is separate and always set; this is the near
    # one, which used to be a fixed two hours for every visit. 60 for the
    # visits saved before the choice existed.
    reminder_lead_minutes: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, server_default=text("60")
    )
    status: Mapped[str] = mapped_column(
        Text, server_default=text("'scheduled'")
    )
    # «فائت» chosen for it from «السجل»: still open, and
    # missed on every page at once.
    marked_missed: Mapped[bool] = mapped_column(
        default=False, server_default=false()
    )
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    # Who last edited it or set its status; empty until
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


class AppointmentCompanion(db.Model):
    """One circle member selected for an appointment. The server requires
    one at least on every save; a companion's row goes with their deleted
    account, and the appointment stays."""

    __tablename__ = "appointment_companion"

    appointment_id: Mapped[UUID] = mapped_column(
        ForeignKey("appointment.id", ondelete="CASCADE"),
        primary_key=True,
    )
    # Goes with a deleted account; the appointment stays.
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"),
        primary_key=True,
        index=True,
    )


class AppointmentVisit(db.Model):
    """A completed appointment's written report and optional voice note."""

    __tablename__ = "appointment_visit"
    __table_args__ = (
        CheckConstraint(
            "summary IS NULL OR char_length(summary) <= 2000",
            name="summary_length",
        ),
        CheckConstraint(
            "recommendations IS NULL OR "
            "char_length(recommendations) <= 2000",
            name="recommendations_length",
        ),
        CheckConstraint(
            "follow_up IS NULL OR char_length(follow_up) <= 500",
            name="follow_up_length",
        ),
        CheckConstraint(
            "audio IS NULL OR octet_length(audio) <= 5242880",
            name="audio_size",
        ),
    )

    appointment_id: Mapped[UUID] = mapped_column(
        ForeignKey("appointment.id", ondelete="CASCADE"), primary_key=True
    )
    summary: Mapped[str | None] = mapped_column(Text)
    recommendations: Mapped[str | None] = mapped_column(Text)
    follow_up: Mapped[str | None] = mapped_column(Text)
    # Loaded only when read: a visit is listed without its recording.
    audio: Mapped[bytes | None] = mapped_column(LargeBinary, deferred=True)
    updated_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
