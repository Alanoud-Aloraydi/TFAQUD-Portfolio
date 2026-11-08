"""Phone-verified accounts, including incomplete onboarding profiles."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class Account(db.Model):
    """An authenticated identity; management is a separate membership."""

    __tablename__ = "account"
    __table_args__ = (
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'",
            name="phone_format",
        ),
        CheckConstraint(
            "app_mode IN ('detailed', 'simplified')",
            name="app_mode",
        ),
        CheckConstraint(
            "(first_name IS NULL AND last_name IS NULL "
            "AND display_name IS NULL) OR "
            "(first_name IS NOT NULL AND last_name IS NOT NULL "
            "AND display_name IS NOT NULL "
            "AND length(btrim(first_name)) BETWEEN 1 AND 50 "
            "AND length(btrim(last_name)) BETWEEN 1 AND 50 "
            "AND length(btrim(display_name)) BETWEEN 1 AND 30)",
            name="profile_names",
        ),
        CheckConstraint(
            "birth_date IS NULL OR birth_date >= DATE '1900-01-01'",
            name="birth_date",
        ),
        CheckConstraint(
            "city IS NULL OR length(btrim(city)) BETWEEN 1 AND 60",
            name="city",
        ),
        CheckConstraint(
            "avatar_code IS NULL OR avatar_code IN "
            "('w1_1', 'w1_3', 'w6_1', 'w6_3', 'w7_1', 'w7_3', "
            "'m1_1', 'm1_3', 'm2_1', 'm2_3', 'm6_1', 'm6_3')",
            name="avatar_code",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    phone_number: Mapped[str] = mapped_column(Text, unique=True)
    first_name: Mapped[str | None] = mapped_column(Text)
    last_name: Mapped[str | None] = mapped_column(Text)
    display_name: Mapped[str | None] = mapped_column(Text)
    avatar_code: Mapped[str | None] = mapped_column(Text)
    app_mode: Mapped[str | None] = mapped_column(Text)
    # Asked once at onboarding, so a circle for the person's own care needs
    # only its name. A circle copies them into its patient when it is
    # created.
    birth_date: Mapped[date | None]
    city: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
