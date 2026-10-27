"""Medication identities and immutable treatment-plan revisions."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index
from sqlalchemy import Integer, String, Text, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class MedicationPlan(db.Model):
    """Stable medication identity for one patient."""

    __tablename__ = "medication_plan"
    __table_args__ = (
        CheckConstraint(
            "length(btrim(current_normalized_name)) > 0",
            name="normalized_name_nonblank",
        ),
        CheckConstraint(
            "discontinued_at IS NOT NULL "
            "OR discontinued_by_account_id IS NULL",
            name="discontinuation_state",
        ),
        Index(
            "ix_medication_plan_patient_name",
            "patient_id",
            "current_normalized_name",
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
    current_normalized_name: Mapped[str] = mapped_column(Text)
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
            "effective_until IS NULL "
            "OR effective_until >= effective_from",
            name="effective_period",
        ),
        UniqueConstraint("medication_plan_id", "version_number"),
        Index(
            "uq_medication_plan_version_current",
            "medication_plan_id",
            unique=True,
            postgresql_where=text("effective_until IS NULL"),
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
    strength_text: Mapped[str | None] = mapped_column(String(50))
    dosage_form: Mapped[str] = mapped_column(Text)
    reason_for_use: Mapped[str | None] = mapped_column(String(100))
    instructions: Mapped[str | None] = mapped_column(String(250))
    treatment_starts_on: Mapped[date] = mapped_column(Date)
    treatment_ends_on: Mapped[date | None] = mapped_column(Date)
    effective_from: Mapped[datetime] = mapped_column(
        DateTime(timezone=True)
    )
    effective_until: Mapped[datetime | None] = mapped_column(
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
