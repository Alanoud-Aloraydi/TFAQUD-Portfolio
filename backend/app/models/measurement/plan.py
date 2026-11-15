"""The `measurement_plan` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.measurement.kinds import KINDS_SQL


class MeasurementPlan(db.Model):
    """A patient's glucose or blood-pressure monitoring plan."""

    __tablename__ = "measurement_plan"
    __table_args__ = (
        CheckConstraint(KINDS_SQL, name="kind"),
        CheckConstraint(
            "stopped_at IS NOT NULL OR stopped_by_account_id IS NULL",
            name="stopped_state",
        ),
        Index(
            "uq_measurement_plan_care_circle_id_kind_active",
            "care_circle_id", "kind", unique=True,
            postgresql_where=text("stopped_at IS NULL"),
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(Text)
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    # Null while the plan is in use.
    stopped_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    # Null while in use, or after that account was deleted.
    stopped_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
