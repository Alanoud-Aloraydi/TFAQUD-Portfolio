"""How long doses are kept: three months. The scheduled tick then deletes
their records for good (app/push/scheduled/purge.py), and the days before
are not answered any more, so a deleted record never comes back as a
missed dose. The app warns five days before a day goes, so its doses can
be exported first."""

from datetime import date, datetime, timedelta

DOSES_KEPT_DAYS = 90


def doses_kept_from(now: datetime) -> datetime:
    """The moment before which an extra dose is deleted."""
    return now - timedelta(days=DOSES_KEPT_DAYS)


def first_kept_day(now: datetime) -> date:
    """The first day whose doses are still kept; the days before are
    deleted."""
    return doses_kept_from(now).date()
