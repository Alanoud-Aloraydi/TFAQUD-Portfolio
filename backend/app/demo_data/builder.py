"""The demo builder, put together: the whole story in one session at
`now`."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.demo_data.aunt import DemoAunt
from app.demo_data.dose_history import DemoDoseHistory
from app.demo_data.mother import DemoMother
from app.demo_data.mother_courses import DemoMotherCourses
from app.demo_data.mother_daily import DemoMotherDaily
from app.demo_data.mother_weekly import DemoMotherWeekly
from app.demo_data.others import DemoOthers
from app.demo_data.own_care import DemoOwnCare
from app.demo_data.people import DemoPeople
from app.demo_data.reading_history import DemoReadingHistory
from app.demo_data.shapes import Summary
from app.demo_data.story import DEMO_ZONE
from app.demo_data.story_build import DemoStory
from app.demo_data.timeline import DemoTimeline
from app.demo_data.uncle import DemoUncle
from app.demo_data.uncle_checks import DemoUncleChecks
from app.demo_data.uncle_medicines import DemoUncleMedicines
from app.demo_data.writes import DemoWrites


class DemoBuilder(
    DemoTimeline,
    DemoPeople,
    DemoWrites,
    DemoDoseHistory,
    DemoReadingHistory,
    DemoOwnCare,
    DemoMother,
    DemoMotherDaily,
    DemoMotherCourses,
    DemoOthers,
    DemoUncle,
    DemoUncleMedicines,
    DemoUncleChecks,
    DemoAunt,
    DemoMotherWeekly,
    DemoStory,
):
    """Make the demo story in one session, at `now` (in `DEMO_ZONE`)."""

    def __init__(self, session: Session, now: datetime):
        """Build inside the caller's session, with Riyadh's time and date as
        the story's «now».
        """
        self.session = session
        self.now = now.astimezone(DEMO_ZONE)
        self.today = self.now.date()
        self.summary = Summary()
