"""A care circle: one patient and the people who care for them."""
from datetime import date
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, ForeignKey, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db

AVATAR_CODES = (
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
)
BLOOD_TYPES = ("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")
_AVATARS_SQL = ", ".join(f"'{code}'" for code in AVATAR_CODES)
_BLOOD_SQL = ", ".join(f"'{code}'" for code in BLOOD_TYPES)


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
    __table_args__ = (
        CheckConstraint(
            "(account_id IS NOT NULL AND name IS NOT NULL "
            "AND first_name IS NULL AND last_name IS NULL "
            "AND avatar_code IS NULL AND birth_date IS NULL "
            "AND city IS NULL) OR (account_id IS NULL AND name IS NULL "
            "AND first_name IS NOT NULL AND last_name IS NOT NULL "
            "AND birth_date IS NOT NULL AND city IS NOT NULL)",
            name="account_source",
        ),
        CheckConstraint(
            "name IS NULL OR length(btrim(name)) BETWEEN 1 AND 60",
            name="name",
        ),
        CheckConstraint(
            "first_name IS NULL OR length(btrim(first_name)) BETWEEN 1 AND 50",
            name="first_name",
        ),
        CheckConstraint(
            "last_name IS NULL OR length(btrim(last_name)) BETWEEN 1 AND 50",
            name="last_name",
        ),
        CheckConstraint(
            "city IS NULL OR length(btrim(city)) BETWEEN 1 AND 60",
            name="city",
        ),
        CheckConstraint(
            "birth_date IS NULL OR birth_date >= DATE '1900-01-01'",
            name="birth_date",
        ),
        CheckConstraint(
            "length(btrim(time_zone)) BETWEEN 1 AND 64", name="time_zone"
        ),
        CheckConstraint("latitude BETWEEN -90 AND 90", name="latitude"),
        CheckConstraint("longitude BETWEEN -180 AND 180", name="longitude"),
        CheckConstraint(f"blood_type IN ({_BLOOD_SQL})", name="blood_type"),
        CheckConstraint(
            f"avatar_code IS NULL OR avatar_code IN ({_AVATARS_SQL})",
            name="avatar_code",
        ),
        CheckConstraint(
            "conditions_status IS NULL OR "
            "conditions_status IN ('none', 'listed')",
            name="conditions_status",
        ),
        CheckConstraint(
            "allergies_status IS NULL OR "
            "allergies_status IN ('none', 'listed')",
            name="allergies_status",
        ),
    )

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
