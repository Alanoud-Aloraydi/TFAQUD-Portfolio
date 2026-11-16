"""The fixed parts of the demo story: its numbers, places, zone and how
far back it goes."""

from datetime import timedelta
from zoneinfo import ZoneInfo

from app.clock import DEFAULT_ZONE

EVERY_DAY = [1, 2, 3, 4, 5, 6, 7]

# A number with no account: the main demo account asks it for a circle.
REQUEST_PHONE = "+966500000003"
# A number with no account: the main demo account invites it to help with
# her mother's care, and the invitation waits.
INVITED_PHONE = "+966559876543"

RIYADH_POINT = (24.7136, 46.6753)
JEDDAH_POINT = (21.4858, 39.1925)
LONDON_POINT = (51.5072, -0.1276)
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
