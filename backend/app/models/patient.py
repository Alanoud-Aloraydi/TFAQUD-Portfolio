"""Patient identity independent of application account ownership."""

from datetime import date
from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class Patient(db.Model):
    """Use account names while linked, and local names after detachment."""

    __tablename__ = "patient"
    __table_args__ = (
        CheckConstraint(
            "(account_id IS NOT NULL AND first_name IS NULL "
            "AND last_name IS NULL) OR "
            "(account_id IS NULL AND first_name IS NOT NULL "
            "AND last_name IS NOT NULL AND length(btrim(first_name)) > 0 "
            "AND length(btrim(last_name)) > 0)",
            name="name_source",
        ),
        CheckConstraint("length(btrim(city)) > 0", name="city_nonblank"),
        CheckConstraint("latitude BETWEEN -90 AND 90", name="latitude"),
        CheckConstraint("longitude BETWEEN -180 AND 180", name="longitude"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
        unique=True,
    )
    account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="RESTRICT"),
        unique=True,
    )
    first_name: Mapped[str | None] = mapped_column(Text)
    last_name: Mapped[str | None] = mapped_column(Text)
    birth_date: Mapped[date]
    city: Mapped[str] = mapped_column(Text)
    latitude: Mapped[float | None]
    longitude: Mapped[float | None]
