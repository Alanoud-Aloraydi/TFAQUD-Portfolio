"""Expand weekly and monthly schedules into calendar occurrences."""

from collections import defaultdict
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

from app.medications.representations import occurrence_response

RIYADH = ZoneInfo("Asia/Riyadh")


def build_occurrences(
    rows,
    days,
    records,
    accounts,
    from_date: date,
    to_date: date,
    now: datetime,
):
    """Build only applicable occurrences, selecting the latest version.

    `rows` are (plan, version, schedule); `days` maps each schedule's id to
    its `ScheduleDays`.
    """
    by_plan = defaultdict(list)
    for row in rows:
        by_plan[row[0].id].append(row)
    result = []
    current = from_date
    while current <= to_date:
        for plan_rows in by_plan.values():
            eligible = [
                row
                for row in plan_rows
                if _version_applies(row[0], row[1], current)
            ]
            if not eligible:
                continue
            version_number = max(row[1].version_number for row in eligible)
            for plan, version, schedule in eligible:
                if version.version_number != version_number or not days[
                    schedule.id
                ].applies_on(current):
                    continue
                scheduled_at = datetime.combine(
                    current, schedule.time_of_day, tzinfo=RIYADH
                )
                if (
                    plan.discontinued_at is not None
                    and scheduled_at >= plan.discontinued_at
                ):
                    continue
                record = records.get((schedule.id, current))
                result.append(
                    occurrence_response(
                        plan,
                        version,
                        schedule,
                        current,
                        record,
                        accounts,
                        _timing_state(
                            scheduled_at,
                            now,
                            record,
                            version.missed_after_minutes,
                        ),
                    )
                )
        current += timedelta(days=1)
    return sorted(
        result,
        key=lambda item: (
            item["scheduled_on"],
            item["time_of_day"],
            item["name"],
        ),
    )


def _version_applies(plan, version, day: date) -> bool:
    if version.treatment_starts_on > day:
        return False
    if version.treatment_ends_on is not None:
        if version.treatment_ends_on < day:
            return False
    if version.effective_from_on > day:
        return False
    if version.effective_until_on is not None:
        if version.effective_until_on <= day:
            return False
    return True


def _timing_state(scheduled_at, now, record, missed_after_minutes):
    """Return timing without persisting calculated occurrences."""
    if record is not None:
        return None
    local_now = now.astimezone(RIYADH)
    if local_now < scheduled_at:
        return "upcoming"
    if local_now < scheduled_at + timedelta(minutes=15):
        return "due"
    if local_now < scheduled_at + timedelta(
        minutes=missed_after_minutes
    ):
        return "late"
    return "missed"
