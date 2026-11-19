"""The `emergency_contact` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.medical.codes import RELATION_OTHER, RELATIONS_SQL


class EmergencyContact(db.Model):
    """A person to call for the patient. One row per phone number."""

    __tablename__ = "emergency_contact"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "phone_number",
            name="uq_emergency_contact_care_circle_id_phone_number",
        ),
        CheckConstraint("length(btrim(name)) BETWEEN 1 AND 50", name="name"),
        CheckConstraint(f"relation IN ({RELATIONS_SQL})", name="relation"),
        CheckConstraint(RELATION_OTHER, name="relation_other"),
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
    )
    name: Mapped[str] = mapped_column(Text)
    relation: Mapped[str] = mapped_column(Text)
    # The relation in the user's words when it is «أخرى».
    relation_other: Mapped[str | None] = mapped_column(Text)
    phone_number: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
