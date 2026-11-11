"""Private photographs, one table per owner (migration 0042)."""
from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, LargeBinary
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db

_SIZE = "octet_length(data) BETWEEN 1 AND 4194304"


class AccountPhoto(db.Model):
    """An account's own photo; a patient with an account shares it."""

    __tablename__ = "account_photo"
    __table_args__ = (CheckConstraint(_SIZE, name="data_size"),)

    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"), primary_key=True
    )
    data: Mapped[bytes] = mapped_column(LargeBinary)


class CareCirclePhoto(db.Model):
    """The photo of a patient without an account."""

    __tablename__ = "care_circle_photo"
    __table_args__ = (CheckConstraint(_SIZE, name="data_size"),)

    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), primary_key=True
    )
    data: Mapped[bytes] = mapped_column(LargeBinary)


class MedicationPlanPhoto(db.Model):
    """A medicine's photo, shared by its versions."""

    __tablename__ = "medication_plan_photo"
    __table_args__ = (CheckConstraint(_SIZE, name="data_size"),)

    medication_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan.id", ondelete="CASCADE"), primary_key=True
    )
    data: Mapped[bytes] = mapped_column(LargeBinary)
