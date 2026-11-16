"""The `care_circle` table."""

from datetime import date
from uuid import UUID

from sqlalchemy import Date, ForeignKey, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.circle.circle_rules import CIRCLE_TABLE_ARGS


class CareCircle(db.Model):
    """The ``care_circle`` table: one row per circle, which is one patient.

    A circle and its patient were one thing in two tables until migration
    0037. While the patient has an account (`account_id`), the names, the
    birth date, the city and the avatar are the account's and are not
    copied here; `name` is then the patient's own name for the circle.
    A patient without an account keeps them here and has no circle name
    (everyone reads «دائرة» and the first name, `app.circles.naming`).
    At least one manager is checked when the transaction commits.
    """

    __tablename__ = "care_circle"
    __table_args__ = CIRCLE_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    # The patient's own name for the circle; null for a patient without an
    # account.
    name: Mapped[str | None] = mapped_column(Text)
    # The patient's account; null for a patient without one.
    account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="RESTRICT"), unique=True
    )
    # Who leads the circle while its patient does not (a patient in the
    # detailed mode always does): whoever made it, or whoever the leader
    # handed it to (`app.circles.leader`).
    leader_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    # Only for a patient without an account (the account holds them
    # otherwise).
    first_name: Mapped[str | None] = mapped_column(Text)
    last_name: Mapped[str | None] = mapped_column(Text)
    avatar_code: Mapped[str | None] = mapped_column(Text)
    birth_date: Mapped[date | None] = mapped_column(Date)
    city: Mapped[str | None] = mapped_column(Text)
    # The IANA zone where the patient lives (e.g. "Asia/Riyadh"): every
    # schedule and "today" of the circle follows it (`app.clock`).
    time_zone: Mapped[str] = mapped_column(Text)
    latitude: Mapped[float | None]
    longitude: Mapped[float | None]
    blood_type: Mapped[str | None] = mapped_column(Text)
    # Null until the medical file answers the question; none or listed.
    conditions_status: Mapped[str | None] = mapped_column(Text)
    allergies_status: Mapped[str | None] = mapped_column(Text)
