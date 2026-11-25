"""Measurement plans: the kinds of measurement, the plan
(`measurement_plan`), and its versions with their weekdays and reading
times. A reading is judged by fixed normal ranges (app.measurements.ranges),
so no plan keeps a target of its own."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    SmallInteger,
    Text,
    Time,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.plan_limits import MISSED_AFTER_CHECK


KINDS = ("glucose", "blood_pressure")

KINDS_SQL = "kind IN ('glucose', 'blood_pressure')"

# «ظروف القياس» a reading time or a reading can have, each once.
CONDITIONS_CHECK = (
    "conditions <@ ARRAY['fasting', 'before_meal', 'after_meal', 'bedtime', "
    "'before_medicine', 'after_medicine', 'morning', "
    "'exertion', 'stress', 'illness', 'other']::text[]"
)

CONDITIONS_ONCE = (
    "fn_measurement_conditions_unique(conditions)"
)


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
    created_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )


class MeasurementPlanWeekday(db.Model):
    """One ISO weekday (1 Monday .. 7 Sunday) of a plan version."""

    __tablename__ = "measurement_plan_weekday"
    __table_args__ = (
        CheckConstraint("weekday BETWEEN 1 AND 7", name="weekday"),
    )

    plan_version_id: Mapped[UUID] = mapped_column(
        ForeignKey(
            "measurement_plan_version.id", ondelete="CASCADE",
            name="fk_measurement_plan_weekday_plan_version_id",
        ),
        primary_key=True,
    )
    weekday: Mapped[int] = mapped_column(SmallInteger, primary_key=True)


class MeasurementPlanTime(db.Model):
    """One reading time of a plan version and its glucose measurement state."""

    __tablename__ = "measurement_plan_time"
    __table_args__ = (
        CheckConstraint(
            "measurement_state IS NULL OR measurement_state IN "
            "('fasting', 'before_meal', 'after_meal', "
            "'before_medicine', 'after_medicine', 'morning')",
            name="measurement_state",
        ),
    )

    plan_version_id: Mapped[UUID] = mapped_column(
        ForeignKey(
            "measurement_plan_version.id", ondelete="CASCADE",
            name="fk_measurement_plan_time_plan_version_id",
        ),
        primary_key=True,
    )
    time_of_day: Mapped[time] = mapped_column(Time, primary_key=True)
    measurement_state: Mapped[str | None] = mapped_column(Text)
