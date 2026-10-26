"""Phone-verified accounts, including incomplete onboarding profiles."""

from datetime import datetime
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
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    phone_number: Mapped[str] = mapped_column(Text, unique=True)
    first_name: Mapped[str | None] = mapped_column(Text)
    last_name: Mapped[str | None] = mapped_column(Text)
    display_name: Mapped[str | None] = mapped_column(Text)
    app_mode: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
