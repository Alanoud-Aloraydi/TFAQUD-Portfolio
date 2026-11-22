"""When a visit's reminders come (reminder_moments.dart, planned_
appointments.dart).

A day before it, and its own lead before it (an hour unless another was
chosen, up to six), each only when that moment came after the visit was
last saved: the app never set one already gone. A visit saved after its
day-before moment is said once instead, half a minute after it was saved,
so a change made the day before is not silent until the visit's own
reminder; unless that near reminder comes within ten minutes anyway."""

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from app.clock import as_utc, local_moment

DAY_BEFORE = timedelta(days=1)
# How long after a visit is saved it is said (`appointmentSavedLead`).
SAVED_LEAD = timedelta(seconds=30)
# A near reminder this close after the saving says it anyway.
SOON_ENOUGH = timedelta(minutes=10)


def visit_moments(visit, zone: ZoneInfo) -> list[tuple[str, datetime]]:
    """The visit's reminders as (lead, moment): "day_before", "soon" and
    "today" (the one said after a late saving)."""
    moment = local_moment(visit.scheduled_on, visit.time_of_day, zone)
    saved = as_utc(visit.updated_at)
    soon = moment - timedelta(minutes=visit.reminder_lead_minutes)
    moments = [
        (lead, at)
        for lead, at in (("day_before", moment - DAY_BEFORE), ("soon", soon))
        if at > saved
    ]
    if saved > moment - DAY_BEFORE:
        at = saved + SAVED_LEAD
        soon_comes = at < soon and soon - at < SOON_ENOUGH
        if at < moment and not soon_comes:
            moments.append(("today", at))
    return moments
