"""Khaled's measurements and appointments."""

from datetime import timedelta

from app.demo_data.story import EVERY_DAY
from app.measurements.inputs import ReadingRequest
from app.measurements.service import MeasurementService


class DemoUncleChecks:
    """Khaled's checks and visits."""

    def _uncle_measurements(self, lina, khaled, circle) -> None:
        """Pressure and sugar with their times, the month behind them, and
        a reading he took himself."""
        self.measure(lina, circle, {
            "kind": "blood_pressure",
            "times": [{"time_of_day": self.clock_in(20)}],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
        })
        self.measure(lina, circle, {
            "kind": "glucose",
            "times": [
                {"time_of_day": "07:00", "measurement_state": "fasting"},
                {
                    "time_of_day": self.clock_in(90),
                    "measurement_state": "after_meal",
                },
            ],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
        })
        # The month behind him, so the chart and the summary have
        # something to show on the first screen he opens.
        self.glucose_history(khaled, circle)
        # A reading Khaled took himself an hour ago, outside the plan.
        MeasurementService(self.session, self.now).record(
            circle.id,
            khaled.id,
            ReadingRequest.model_validate({
                "kind": "glucose",
                "outcome": "read",
                "measured_at": self.now - timedelta(hours=1),
                "glucose_value": 135,
                "conditions": ["after_meal"],
            }),
        )

    def _uncle_visits(self, lina, sara, circle) -> None:
        """Three appointments: Lina's, Sara's, and one both go to."""
        visits = (
            (
                *self.visit_in(180), "عيادة القلب", "follow_up",
                "مستشفى الملك فيصل التخصصي", [lina.id],
            ),
            (1, "10:00", "مختبر المستشفى", "test", "مختبر البرج", [sara.id]),
            (5, "11:30", "عيادة العيون", "remote", None, [lina.id, sara.id]),
        )
        for day, clock, specialty, kind, place, going in visits:
            self.appointment(lina, circle, {
                "specialty": specialty,
                "kind": kind,
                "scheduled_on": self.day(day),
                "time_of_day": clock,
                "place": place,
                "remote_method": "video" if kind == "remote" else None,
                "companion_account_ids": going,
            })
