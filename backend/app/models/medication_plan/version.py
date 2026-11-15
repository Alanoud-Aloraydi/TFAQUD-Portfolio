"""The `medication_plan_version` table."""

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.medication_plan.version_rules import VERSION_TABLE_ARGS


class MedicationPlanVersion(db.Model):
    """One immutable version of medication details and treatment dates."""

    __tablename__ = "medication_plan_version"
    __table_args__ = VERSION_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    medication_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan.id", ondelete="CASCADE"),
    )
    version_number: Mapped[int] = mapped_column(Integer)
    name: Mapped[str] = mapped_column(Text)
    # Derived key of `name` (NFKC, casefold, one space) that the overlap
    # rule compares; kept because SQL cannot reproduce it exactly.
    normalized_name: Mapped[str] = mapped_column(Text)
    strength_value: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    strength_unit: Mapped[str] = mapped_column(Text)
    dosage_form: Mapped[str] = mapped_column(Text)
    reason_for_use: Mapped[str | None] = mapped_column(Text)
    instructions: Mapped[str | None] = mapped_column(Text)
    missed_after_minutes: Mapped[int] = mapped_column(SmallInteger)
    treatment_starts_on: Mapped[date] = mapped_column(Date)
    # Null for a treatment with no end.
    treatment_ends_on: Mapped[date | None] = mapped_column(Date)
    effective_from_on: Mapped[date] = mapped_column(Date)
    # Null for the version in force with no successor.
    effective_until_on: Mapped[date | None] = mapped_column(Date)
    # Null unless an edit replaced this version before it started.
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
