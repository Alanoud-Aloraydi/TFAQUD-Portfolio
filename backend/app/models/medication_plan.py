"""Medication identities and immutable treatment-plan revisions."""

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index
from sqlalchemy import Integer, Numeric, String, Text, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MedicationPlan(db.Model):
    """Stable medication identity for one patient."""

    __tablename__ = "medication_plan"
    __table_args__ = (
        CheckConstraint(
            "discontinued_at IS NOT NULL "
            "OR discontinued_by_account_id IS NULL",
            name="discontinuation_state",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    patient_id: Mapped[UUID] = mapped_column(
        ForeignKey("patient.id", ondelete="CASCADE"),
    )
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
    discontinued_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    discontinued_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )


class MedicationPlanVersion(db.Model):
    """One immutable version of medication details and treatment dates."""

    __tablename__ = "medication_plan_version"
    __table_args__ = (
        CheckConstraint("version_number >= 1", name="version_number"),
        CheckConstraint("length(btrim(name)) > 0", name="name_nonblank"),
        CheckConstraint(
            "length(btrim(normalized_name)) > 0",
            name="normalized_name_nonblank",
        ),
        CheckConstraint(
            "dosage_form IN "
            "('tablet', 'capsule', 'liquid', 'drops', "
            "'inhaler', 'injection')",
            name="dosage_form",
        ),
        CheckConstraint(
            "treatment_ends_on IS NULL "
            "OR treatment_ends_on >= treatment_starts_on",
            name="treatment_dates",
        ),
        CheckConstraint(
            "effective_until_on IS NULL "
            "OR effective_until_on > effective_from_on",
            name="effective_period",
        ),
        CheckConstraint(
            "treatment_ends_on IS NULL "
            "OR treatment_ends_on >= effective_from_on",
            name="effective_treatment",
        ),
        CheckConstraint("strength_value > 0", name="positive_strength"),
        CheckConstraint(
            "strength_unit IN ('mg', 'mcg', 'mg/mL', 'mg/5mL', "
            "'mcg/dose', 'unit/mL', '%')",
            name="strength_unit",
        ),
        UniqueConstraint("medication_plan_id", "version_number"),
        UniqueConstraint(
            "medication_plan_id",
            "effective_from_on",
            name="uq_medication_plan_version_effective_from_on",
        ),
        Index(
            "uq_medication_plan_version_open",
            "medication_plan_id",
            unique=True,
            postgresql_where=text("effective_until_on IS NULL"),
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    medication_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey("medication_plan.id", ondelete="CASCADE"),
    )
    version_number: Mapped[int] = mapped_column(Integer)
    name: Mapped[str] = mapped_column(String(50))
    normalized_name: Mapped[str] = mapped_column(Text)
    strength_value: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    strength_unit: Mapped[str] = mapped_column(Text)
    dosage_form: Mapped[str] = mapped_column(Text)
    reason_for_use: Mapped[str | None] = mapped_column(String(100))
    instructions: Mapped[str | None] = mapped_column(String(250))
    treatment_starts_on: Mapped[date] = mapped_column(Date)
    treatment_ends_on: Mapped[date | None] = mapped_column(Date)
    effective_from_on: Mapped[date] = mapped_column(Date)
    effective_until_on: Mapped[date | None] = mapped_column(Date)
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
