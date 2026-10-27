"""Expand weekly schedules into calendar occurrences."""

from collections import defaultdict
from datetime import date, timedelta

from app.medications.representations import occurrence_response


def build_occurrences(rows, records, from_date: date, to_date: date):
    """Build only applicable occurrences, selecting the latest version."""
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
            for plan, version, schedule, weekday in eligible:
                if (
                    version.version_number != version_number
                    or weekday != current.isoweekday()
                ):
                    continue
                result.append(
                    occurrence_response(
                        plan,
                        version,
                        schedule,
                        current,
                        records.get((schedule.id, current)),
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
    if version.effective_from.date() > day:
        return False
    if version.effective_until is not None:
        if version.effective_until.date() < day:
            return False
    return not (
        plan.discontinued_at is not None
        and plan.discontinued_at.date() < day
    )
