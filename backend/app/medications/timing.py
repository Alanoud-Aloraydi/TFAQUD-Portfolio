"""Whether a version is in force on a day, and how late a dose is."""

from datetime import date, timedelta


def version_applies(version, day: date) -> bool:
    """Whether the medicine version is in force on `day`: inside its treatment
    dates and its own start and end.
    """
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


def timing_state(scheduled_at, now, record, missed_after_minutes):
    """Return timing without persisting calculated occurrences.

    `scheduled_at` and `now` are instants (`local_moment` gives UTC), so the
    minutes are real minutes even across a DST change."""
    if record is not None:
        return None
    if now < scheduled_at:
        return "upcoming"
    if now < scheduled_at + timedelta(minutes=15):
        return "due"
    if now < scheduled_at + timedelta(minutes=missed_after_minutes):
        return "late"
    return "missed"
