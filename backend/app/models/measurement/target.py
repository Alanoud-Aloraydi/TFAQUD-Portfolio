"""The `measurement_target` table."""

from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    ForeignKey,
    SmallInteger,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.measurement.kinds import KINDS_SQL, TARGET_BY_KIND


class MeasurementTarget(db.Model):
    """The target once saved for one patient and measurement kind, for
    readings without a plan. Fixed ranges replaced it (0049): it is kept
    with its data and no longer read or written."""

    __tablename__ = "measurement_target"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "kind",
            name="uq_measurement_target_care_circle_id_kind",
        ),
        CheckConstraint(KINDS_SQL, name="kind"),
        CheckConstraint(TARGET_BY_KIND, name="target_shape"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE")
    )
    kind: Mapped[str] = mapped_column(Text)
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
