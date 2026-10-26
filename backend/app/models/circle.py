"""Shared care coordination for exactly one patient."""

from uuid import UUID

from sqlalchemy import CheckConstraint, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class CareCircle(db.Model):
    """Membership and patient existence are checked at transaction commit."""

    __tablename__ = "care_circle"
    __table_args__ = (
        CheckConstraint("length(btrim(name)) > 0", name="name_nonblank"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    name: Mapped[str] = mapped_column(Text)
