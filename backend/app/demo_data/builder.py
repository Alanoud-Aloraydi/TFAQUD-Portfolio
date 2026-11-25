"""The demo builder: the whole story in one session at `now`, its days and
moments counted in the demo's zone, the demo accounts with their medical
files, and writing through the app's own services."""

from datetime import date, datetime, time, timedelta

from sqlalchemy.orm import Session

from app.appointments.inputs import AppointmentRequest
from app.appointments.service import AppointmentService
from app.circles.inputs import MedicalProfileInput
from app.demo import DEMO_ACCOUNTS
from app.demo_data.family import DemoStory
from app.demo_data.history import DemoDoseHistory
from app.demo_data.mother import DemoMother
from app.demo_data.story import DEMO_ZONE, Summary
from app.demo_data.uncle import DemoUncle
from app.measurements.inputs import (
    PlanRequest as MeasurementPlanRequest,
    ReadingRequest,
)
from app.measurements.service import MeasurementService
from app.medical import MedicalService
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plans import MedicationPlanService
from app.models import Account, CareCircle, MedicationPlan


class DemoBuilder(DemoDoseHistory, DemoMother, DemoUncle, DemoStory):
    """Make the demo story in one session, at `now` (in `DEMO_ZONE`)."""

    def __init__(self, session: Session, now: datetime):
        """Build inside the caller's session, with Riyadh's time and date as
        the story's «now».
        """
        self.session = session
        self.now = now.astimezone(DEMO_ZONE)
        self.today = self.now.date()
        self.summary = Summary()

    # Days and moments around now.
    def day(self, offset: int) -> date:
        """The date `offset` days from today."""
        return self.today + timedelta(days=offset)

    def at(self, offset: int, hour: int = 9, minute: int = 0) -> datetime:
        """Riyadh time on the day `offset` days from today."""
        return datetime.combine(
            self.day(offset), time(hour, minute), tzinfo=DEMO_ZONE
        )

    def clock_in(self, minutes: int) -> str:
        """The «HH:MM» time `minutes` from now, on a five-minute mark and
        kept within today, so a task falls where the story wants it: done,
        late, next or later."""
        moment = self.now + timedelta(minutes=minutes)
        start = datetime.combine(self.today, time(0, 5), tzinfo=DEMO_ZONE)
        end = datetime.combine(self.today, time(23, 55), tzinfo=DEMO_ZONE)
        moment = min(max(moment, start), end)
        return f"{moment.hour:02d}:{moment.minute - moment.minute % 5:02d}"

    def visit_in(self, minutes: int) -> tuple[int, str]:
        """The day (0 today, 1 tomorrow) and «HH:MM» of a visit `minutes`
        from now: today at `clock_in(minutes)` while that is still ahead;
        in the last minutes before midnight, when it is not, tomorrow at
        that time from now, since a visit cannot be made in the past."""
        clock = self.clock_in(minutes)
        hour, minute = (int(part) for part in clock.split(":"))
        today = datetime.combine(
            self.today, time(hour, minute), tzinfo=DEMO_ZONE
        )
        if today >= self.now:
            return 0, clock
        moment = self.now + timedelta(minutes=minutes)
        return 1, f"{moment.hour:02d}:{moment.minute - moment.minute % 5:02d}"

    # Makes the people and their files.
    def accounts(self) -> list[Account]:
        """Make the demo accounts (Lina, Sara and Khaled)."""
        rows = [
            Account(
                phone_number=phone,
                first_name=first,
                last_name=last,
                display_name=display,
                birth_date=birth_date,
                city=city,
            )
            for phone, first, last, display, birth_date, city in DEMO_ACCOUNTS
        ]
        self.session.add_all(rows)
        self.session.flush()
        return rows

    def medical(self, actor: Account, circle: CareCircle, profile: dict):
        """Fill a demo patient's medical profile, as written two months ago."""
        MedicalService(self.session, self.at(-60)).update_profile(
            actor.id,
            circle.id,
            MedicalProfileInput.model_validate(profile).to_update(),
        )

    # Writes through the services.
    def create(self, actor, circle, body, when) -> MedicationPlan:
        """Add a demo medicine, as added at `when`."""
        plan = MedicationPlanService(self.session, when).create(
            circle.id, actor.id, PlanRequest.model_validate(body)
        )
        self.summary.plans += 1
        return plan

    def revise(self, actor, circle, plan, version, body, effective, when):
        """Edit a demo medicine, as edited at `when`, from `effective` on."""
        MedicationPlanService(self.session, when).revise(
            circle.id,
            plan.id,
            actor.id,
            RevisePlanRequest.model_validate(
                {
                    **body,
                    "expected_version_number": version,
                    "effective_from_on": effective,
                }
            ),
        )
        self.summary.revisions += 1

    def measure(self, actor, circle, body) -> None:
        """Add a demo measurement plan."""
        MeasurementService(self.session, self.now).create(
            circle.id, actor.id, MeasurementPlanRequest.model_validate(body)
        )

    def reading(self, actor, circle, body) -> None:
        """Record one demo reading, at the moment the body names."""
        MeasurementService(self.session, self.now).record(
            circle.id, actor.id, ReadingRequest.model_validate(body)
        )

    def appointment(self, actor, circle, body) -> None:
        """Add a demo appointment."""
        AppointmentService(self.session, self.now).create(
            circle.id, actor.id, AppointmentRequest.model_validate(body)
        )
