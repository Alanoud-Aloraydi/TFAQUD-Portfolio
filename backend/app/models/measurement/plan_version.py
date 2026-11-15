"""The `measurement_plan_version` table."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    SmallInteger,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.plan_limits import MISSED_AFTER_CHECK


class MeasurementPlanVersion(db.Model):
    """A plan's days and grace over an immutable date range; its
    reading times are `MeasurementPlanTime` rows and its weekdays
    `MeasurementPlanWeekday` rows."""

    __tablename__ = "measurement_plan_version"
    __table_args__ = (
        UniqueConstraint(
            "measurement_plan_id", "version_number",
            name="uq_measurement_plan_version_measurement_plan_id_"
            "version_number",
        ),
        UniqueConstraint(
            "measurement_plan_id", "effective_from_on",
            name="uq_measurement_plan_version_measurement_plan_"
            "effective_from_on",
        ),
        CheckConstraint("version_number > 0", name="version_number"),
        CheckConstraint(
            MISSED_AFTER_CHECK,
            name="missed_after_minutes",
        ),
        CheckConstraint(
            "effective_until_on IS NULL OR "
            "effective_until_on > effective_from_on",
            name="effective_period",
        ),
        # None since fixed ranges judge readings (0049), or an old target.
        CheckConstraint(
            "(glucose_low IS NULL AND glucose_high IS NULL "
            "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
            "AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 "
            "AND glucose_high > glucose_low "
            "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(glucose_low IS NULL AND glucose_high IS NULL "
            "AND systolic_limit BETWEEN 1 AND 999 "
            "AND diastolic_limit BETWEEN 1 AND 999 "
            "AND systolic_limit > diastolic_limit)",
            name="target_shape",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    measurement_plan_id: Mapped[UUID] = mapped_column(
        ForeignKey(
            "measurement_plan.id", ondelete="CASCADE",
            name="fk_measurement_plan_version_measurement_plan_id",
        )
    )
    version_number: Mapped[int] = mapped_column(Integer)
    effective_from_on: Mapped[date] = mapped_column(Date)
    # Null for the version in force with no successor.
    effective_until_on: Mapped[date | None] = mapped_column(Date)
    missed_after_minutes: Mapped[int] = mapped_column(SmallInteger)
    # The target this version judged readings by, before fixed ranges
    # (0049); none for a newer version.
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
