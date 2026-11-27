"""The fixed parts of the demo story (its numbers, places, zone and how far
back it goes), the shapes of a demo medicine and its doses, and the
summary at the end."""

from dataclasses import dataclass, field
from datetime import timedelta
from zoneinfo import ZoneInfo

from app.clock import DEFAULT_ZONE
from app.demo import REQUEST_DEMO_PHONE


EVERY_DAY = [1, 2, 3, 4, 5, 6, 7]

# The main demo account asks this number for a circle. It has no account
# unless the team signed in with it (it takes the demo code).
REQUEST_PHONE = REQUEST_DEMO_PHONE

# A number with no account: the main demo account invites it to help with
# her mother's care, and the invitation waits.
INVITED_PHONE = "+966559876543"

# The story is told in Riyadh's time: every demo patient lives in a listed
# Saudi city and has this zone, except Lina's aunt in London, whose doses
# follow her own zone (`DemoBuilder.aunt`).
DEMO_ZONE = ZoneInfo(DEFAULT_ZONE)

# How far back the dose records go.
HISTORY_DAYS = 30

# Today's doses due in this window before now are left without a record,
# so the app shows them as due, late or missed.
OPEN_WINDOW = timedelta(hours=3)

SKIP_REASONS = (
    "forgotten",
    "unavailable",
    "side_effects",
    "patient_refused",
    "other",
)


@dataclass
class Summary:
    """What was made, for the message at the end."""

    circles: list[str] = field(default_factory=list)
    plans: int = 0
    revisions: int = 0
    taken: int = 0
    skipped: int = 0
    open_doses: int = 0


def dose_at(clock, dose, unit, days=EVERY_DAY, instructions=None):
    """One dose time of a demo medicine, in the shape the medicine request
    takes.
    """
    return {
        "time_of_day": clock,
        "dose_value": dose,
        "dose_unit": unit,
        "weekdays": list(days),
        "instructions": instructions,
    }


def medicine(name, strength, unit, form, schedules, starts, ends=None, **more):
    """One demo medicine, in the shape the medicine request takes."""
    return {
        "name": name,
        "strength_value": strength,
        "strength_unit": unit,
        "dosage_form": form,
        "treatment_starts_on": starts,
        "treatment_ends_on": ends,
        "schedules": schedules,
        **more,
    }
