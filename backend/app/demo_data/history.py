"""A month of history behind the demo: doses behind each medicine, each
with a status, and pressure and sugar readings behind a plan."""

import random
from datetime import date, datetime, time, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from app.demo_data.story import HISTORY_DAYS, OPEN_WINDOW, SKIP_REASONS
from app.medications.dose_inputs import DoseRecordRequest
from app.medications.doses import MedicationDoseService
from app.medications.queries import MedicationQueries
from app.models import Account, CareCircle


class DemoDoseHistory:
    """Records past doses."""

    def history(self, actor: Account, circle: CareCircle) -> None:
        """Record the past doses of a circle, as a family would have.

        About 8 in 10 doses are taken (some late), about 1 in 10 skipped with
        a reason, and the rest have no record (missed). Today's doses due in
        the last 3 hours stay open, and later ones are still to come.
        The choice per dose is fixed by the dose itself, so a reset gives
        the same picture.
        """
        queries = MedicationQueries(self.session, self.now)
        start = self.day(-HISTORY_DAYS)
        while start <= self.today:
            end = min(start + timedelta(days=30), self.today)
            for item in queries.occurrences(circle.id, start, end):
                self._record(actor, circle, item)
            start = end + timedelta(days=1)

    def _record(self, actor: Account, circle: CareCircle, item: dict):
        """Record a past demo dose the way a family would: most taken a few
        minutes late, some skipped with a reason, a few never recorded; the
        same dose always gets the same story. Doses still open are left for the
        app.
        """
        # Only a past dose with no record, and not one still open (the app
        # shows those as due).
        if item.get("record") is not None:
            return
        # A dose's time is wall clock in the patient's own zone.
        zone = ZoneInfo(circle.time_zone)
        scheduled_on = date.fromisoformat(item["scheduled_on"])
        due = datetime.combine(
            scheduled_on,
            time.fromisoformat(item["time_of_day"]),
            tzinfo=zone,
        )
        if due > self.now:
            return
        if due > self.now - OPEN_WINDOW:
            self.summary.open_doses += 1
            return
        # The same dose always rolls the same number.
        chance = random.Random(
            f"{item['name']}|{item['scheduled_on']}|{item['time_of_day']}"
        )
        roll = chance.random()
        today = scheduled_on == self.now.astimezone(zone).date()
        # Taken (every dose of today, and 80% of the others): up to 10 minutes
        # early or 45 late, recorded a few minutes after.
        if today or roll < 0.80:
            taken_at = due + timedelta(minutes=chance.randint(-10, 45))
            recorded_at = min(
                max(taken_at, due) + timedelta(minutes=3), self.now
            )
            body = {"outcome": "taken", "taken_at": min(taken_at, recorded_at)}
            self.summary.taken += 1
        # Skipped (12%), with a reason; the rest (8%) stay unrecorded.
        elif roll < 0.92:
            reason = chance.choice(SKIP_REASONS)
            recorded_at = min(due + timedelta(minutes=45), self.now)
            body = {"outcome": "skipped", "skip_reason_code": reason}
            if reason == "other":
                body["skip_reason_note"] = "كانت نائمة وقت الجرعة"
            self.summary.skipped += 1
        else:
            return
        # Record it as the app would, at the time it was recorded.
        MedicationDoseService(self.session, recorded_at).record(
            circle.id,
            UUID(item["schedule_id"]),
            scheduled_on,
            actor.id,
            DoseRecordRequest.model_validate(body),
        )

    # Records past readings.
    def pressure_history(self, actor, circle, days: int = 24) -> None:
        """A month of blood pressure, morning and evening, so the chart
        has a shape to draw: mostly in range, with a few high mornings
        that the chart marks and the summary counts."""
        for offset in range(-days, 0):
            swing = (offset * 7) % 11
            high = offset % 8 == 0
            for hour, lift in ((8, 6), (20, 0)):
                systolic = 118 + swing + lift + (22 if high else 0)
                diastolic = 74 + swing % 7 + (10 if high else 0)
                self.reading(actor, circle, {
                    "kind": "blood_pressure",
                    "outcome": "read",
                    "measured_at": self.at(offset, hour),
                    "systolic_value": systolic,
                    "diastolic_value": diastolic,
                })

    def glucose_history(self, actor, circle, days: int = 24) -> None:
        """A month of sugar: fasting in the morning, after food at noon."""
        for offset in range(-days, 0):
            swing = (offset * 5) % 13
            high = offset % 7 == 0
            self.reading(actor, circle, {
                "kind": "glucose",
                "outcome": "read",
                "measured_at": self.at(offset, 7),
                "glucose_value": 96 + swing + (38 if high else 0),
                "conditions": ["fasting"],
            })
            self.reading(actor, circle, {
                "kind": "glucose",
                "outcome": "read",
                "measured_at": self.at(offset, 14),
                "glucose_value": 138 + swing + (52 if high else 0),
                "conditions": ["after_meal"],
            })
