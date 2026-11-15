"""The weekdays and reading times of a measurement plan version."""

from datetime import time
from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, SmallInteger, Text, Time
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


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
