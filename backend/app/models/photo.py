"""Private photographs for accounts, patients, and medication plans."""

from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, LargeBinary
from sqlalchemy import UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class Photo(db.Model):
    """Keep one bounded photograph per owner outside ordinary list rows."""

    __tablename__ = "photo"
    __table_args__ = (
        CheckConstraint(
            "num_nonnulls(account_id, patient_id, medication_plan_id) = 1",
            name="one_owner",
        ),
        CheckConstraint(
            "octet_length(data) BETWEEN 1 AND 4194304",
            name="bounded_data",
        ),
        UniqueConstraint("account_id"),
        UniqueConstraint("patient_id"),
        UniqueConstraint("medication_plan_id"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE")
    )
    patient_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE")
    )
    medication_plan_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("medication_plan.id", ondelete="CASCADE")
    )
    data: Mapped[bytes] = mapped_column(LargeBinary)
