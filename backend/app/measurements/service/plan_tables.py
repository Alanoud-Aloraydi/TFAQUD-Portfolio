"""A circle's patient, and the times, weekdays and meal states of plan
versions."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import NotFound
from app.models import (
    CareCircle,
    MeasurementPlanTime,
    MeasurementPlanWeekday,
    MeasurementReading,
)


def circle_for(session: Session, circle_id: UUID) -> CareCircle:
    """Find the circle (its patient) without leaking other circles."""
    circle = session.get(CareCircle, circle_id)
    if circle is None:
        raise NotFound()
    return circle


def plan_times(
    session: Session, version_ids
) -> dict[UUID, list[MeasurementPlanTime]]:
    """The reading times of each version, earliest first."""
    ids = list(version_ids)
    result: dict[UUID, list[MeasurementPlanTime]] = {key: [] for key in ids}
    if ids:
        for item in session.scalars(
            select(MeasurementPlanTime)
            .where(MeasurementPlanTime.plan_version_id.in_(ids))
            .order_by(MeasurementPlanTime.time_of_day)
        ):
            result[item.plan_version_id].append(item)
    return result


def plan_weekdays(session: Session, version_ids) -> dict[UUID, list[int]]:
    """The ISO weekdays of each version, Monday first."""
    ids = list(version_ids)
    result: dict[UUID, list[int]] = {key: [] for key in ids}
    if ids:
        for item in session.scalars(
            select(MeasurementPlanWeekday)
            .where(MeasurementPlanWeekday.plan_version_id.in_(ids))
            .order_by(MeasurementPlanWeekday.weekday)
        ):
            result[item.plan_version_id].append(item.weekday)
    return result


def planned_state(
    session: Session, reading: MeasurementReading
) -> str | None:
    """The meal state the plan time of a reading planned, if any."""
    if reading.plan_version_id is None or reading.scheduled_time is None:
        return None
    return session.scalar(
        select(MeasurementPlanTime.measurement_state).where(
            MeasurementPlanTime.plan_version_id == reading.plan_version_id,
            MeasurementPlanTime.time_of_day == reading.scheduled_time,
        )
    )
