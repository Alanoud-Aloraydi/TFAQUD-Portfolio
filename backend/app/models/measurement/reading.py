"""The `measurement_reading` table."""

from datetime import date, datetime, time
from uuid import UUID

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    SmallInteger,
    Text,
    Time,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.measurement.reading_rules import READING_TABLE_ARGS


class MeasurementReading(db.Model):
    """A reading or an explicit skip of a plan's reading time, or a reading
    taken outside a plan."""

    __tablename__ = "measurement_reading"
    __table_args__ = READING_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"), index=True
    )
    # Null for a reading taken outside a plan.
    plan_version_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("measurement_plan_version.id", ondelete="CASCADE")
    )
    scheduled_on: Mapped[date | None] = mapped_column(Date)
    # Which reading time of that day; null for a reading outside a plan.
    scheduled_time: Mapped[time | None] = mapped_column(Time)
    kind: Mapped[str] = mapped_column(Text)
    outcome: Mapped[str] = mapped_column(Text)
    # Null for a skip.
    measured_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    glucose_value: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_value: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_value: Mapped[int | None] = mapped_column(SmallInteger)
    conditions: Mapped[list[str]] = mapped_column(
        ARRAY(Text), server_default=text("'{}'"), default=list
    )
    # What «أخرى» was, in the reader's words: «بعد القهوة».
    other_text: Mapped[str | None] = mapped_column(Text)
    note: Mapped[str | None] = mapped_column(Text)
    skip_reason_code: Mapped[str | None] = mapped_column(Text)
    skip_reason_note: Mapped[str | None] = mapped_column(Text)
    # The target a reading outside a plan was judged by, before fixed
    # ranges (0049); none for a newer reading.
    glucose_low: Mapped[int | None] = mapped_column(SmallInteger)
    glucose_high: Mapped[int | None] = mapped_column(SmallInteger)
    systolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    diastolic_limit: Mapped[int | None] = mapped_column(SmallInteger)
    followed_up_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    recorded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"), index=True
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
