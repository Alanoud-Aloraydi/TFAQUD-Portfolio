"""The care circle, which is one patient (`care_circle`), with its rules
and codes, and the accounts that manage it (`care_circle_manager`)."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


AVATAR_CODES = (
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
    "sh_1", "sh_3", "gh_3",
)

BLOOD_TYPES = ("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")

AVATARS_SQL = ", ".join(f"'{code}'" for code in AVATAR_CODES)

BLOOD_SQL = ", ".join(f"'{code}'" for code in BLOOD_TYPES)

CIRCLE_TABLE_ARGS = (
    # Without an account the name is the managers' choice, or none.
    CheckConstraint(
        "(account_id IS NOT NULL AND name IS NOT NULL "
        "AND first_name IS NULL AND last_name IS NULL "
        "AND avatar_code IS NULL AND birth_date IS NULL "
        "AND city IS NULL) OR (account_id IS NULL "
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
    CheckConstraint(f"blood_type IN ({BLOOD_SQL})", name="blood_type"),
    CheckConstraint(
        f"avatar_code IS NULL OR avatar_code IN ({AVATARS_SQL})",
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


class CareCircle(db.Model):
    """The ``care_circle`` table: one row per circle, which is one patient.

    While the patient has an account (`account_id`), the names, the
    birth date, the city and the avatar are the account's and are not
    copied here; `name` is then the patient's own name for the circle.
    A patient without an account keeps them here; the circle's name is
    then the one its managers chose, or none (everyone reads «دائرة» and
    the first name, `app.circles.naming`).
    At least one manager is checked when the transaction commits.
    """

    __tablename__ = "care_circle"
    __table_args__ = CIRCLE_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    # The patient's own name for the circle; for a patient without an
    # account, the managers' name, or null.
    name: Mapped[str | None] = mapped_column(
        Text,
        comment=(
            "The patient's own name for the circle; null for a patient "
            "without an account (others read «دائرة» and the name)."
        ),
    )
    account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="RESTRICT"),
        unique=True,
        comment="The patient's account; null for a patient without one.",
    )
    # Who leads the circle while its patient does not (a patient in the
    # detailed mode always does): whoever made it, or whoever the leader
    # handed it to (`app.circles.leader`).
    leader_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL")
    )
    # Only for a patient without an account (the account holds them
    # otherwise).
    first_name: Mapped[str | None] = mapped_column(
        Text,
        comment=(
            "Only for a patient without an account; an account's patient "
            "reads the account's names."
        ),
    )
    last_name: Mapped[str | None] = mapped_column(Text)
    avatar_code: Mapped[str | None] = mapped_column(Text)
    birth_date: Mapped[date | None] = mapped_column(
        Date,
        comment="Only for a patient without an account.",
    )
    city: Mapped[str | None] = mapped_column(Text)
    # The IANA zone where the patient lives (e.g. "Asia/Riyadh"): every
    # schedule and "today" of the circle follows it (`app.clock`).
    time_zone: Mapped[str] = mapped_column(Text)
    blood_type: Mapped[str | None] = mapped_column(Text)
    # Null until the medical file answers the question; none or listed.
    conditions_status: Mapped[str | None] = mapped_column(
        Text,
        comment="Null until the question is answered; none or listed.",
    )
    allergies_status: Mapped[str | None] = mapped_column(
        Text,
        comment="Null until the question is answered; none or listed.",
    )


class CareCircleManager(db.Model):
    """An account can manage many circles, once in each circle."""

    __tablename__ = "care_circle_manager"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "account_id",
            name="uq_care_circle_manager_care_circle_id_account_id",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
    )
    # The server removes a membership before the account goes, so the
    # database refuses a deletion that skipped that step.
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="RESTRICT"),
        index=True,
    )
    # The circle's leader lets each member edit the medicines, the
    # measurements and the appointments, or not (`app.circles.leader`). A
    # membership with all three off stays in the circle, readable, without
    # any write route.
    can_edit_medications: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
    can_edit_measurements: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
    can_edit_appointments: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
    # When the account joined: the leadership falls to the member who joined
    # first when the leader leaves.
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    def may_edit(self, area: str) -> bool:
        """Whether this member may edit the `area` («medications»,
        «measurements» or «appointments»)."""
        return bool(getattr(self, f"can_edit_{area}"))

    @property
    def can_edit_any(self) -> bool:
        """Whether this member may edit at least one area."""
        return (
            self.can_edit_medications
            or self.can_edit_measurements
            or self.can_edit_appointments
        )
