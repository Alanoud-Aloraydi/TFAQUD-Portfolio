"""5. Lina's uncle Khaled, the patient of his own circle in the simplified
mode: his medicines (a dose of each status today), measurements and
appointments."""

from datetime import timedelta

from app.care import CareService
from app.demo_data.story import EVERY_DAY, RIYADH_POINT, dose_at, medicine
from app.measurements.inputs import ReadingRequest
from app.measurements.service import MeasurementService
from app.medical import MedicalService
from app.models import CareCircle


class DemoUncle:
    """Khaled's circle and file."""

    def uncle(self, lina, sara, khaled) -> CareCircle:
        """5. Lina's uncle Khaled, the patient of his own circle in the
        simplified mode, cared for by Lina and Sara. His day has a dose of
        each status (done, late, next, later), a weekly, a monthly and an
        every-other-day medicine, two measurements with their targets, and
        three appointments: one Lina goes to, one only Sara goes to (Lina's
        phone is not reminded of it), and one both go to.
        """
        circle = self._uncle_circle(lina, sara, khaled)
        self._uncle_medicines(lina, circle)
        self._uncle_measurements(lina, khaled, circle)
        self._uncle_visits(lina, sara, circle)
        return circle

    def _uncle_circle(self, lina, sara, khaled) -> CareCircle:
        """His circle, from Lina's request he accepted, with Sara invited,
        his file and a contact."""
        care = CareService(self.session, self.at(-10))
        request = care.request_creation(
            lina.id, khaled.phone_number, "simplified"
        )
        care.respond_creation(khaled.id, request.id, True)
        circle = care.complete_creation(
            khaled.id,
            request.id,
            khaled.birth_date,
            khaled.city,
            *RIYADH_POINT,
            name="صحتي",
        )
        invitation = care.invite_manager(
            lina.id, circle.id, sara.phone_number
        )
        care.respond_invitation(sara.id, invitation.id, True)
        self.medical(
            lina,
            circle,
            {
                "blood_type": "B+",
                "conditions": {
                    "status": "listed",
                    "codes": ["hypertension", "diabetes"],
                },
                "allergies": {
                    "status": "listed",
                    "medication": [],
                    "food": ["tree_nuts"],
                },
            },
        )
        MedicalService(self.session, self.at(-10)).add_contact(
            lina.id, circle.id, "فهد العتيبي", "son", None, "+966500000021"
        )
        return circle

    # Khaled's medicines.
    def _uncle_medicines(self, lina, circle) -> None:
        """A dose of each status today, and a monthly and an every-other-day
        medicine."""
        week = self.day(-7)
        medicines = (
            # Taken this morning.
            (
                "أملوديبين", "5", "mg",
                dose_at(self.clock_in(-240), "1", "tablet"),
                "الضغط",
            ),
            # Its time passed and nobody recorded it: late.
            (
                "ميتفورمين", "500", "mg",
                dose_at(
                    self.clock_in(-40), "1", "tablet",
                    instructions="مع الأكل",
                ),
                "السكر",
            ),
            # The next one.
            (
                "أتورفاستاتين", "20", "mg",
                dose_at(
                    self.clock_in(45), "1", "tablet",
                    instructions="بعد العشاء",
                ),
                "الكوليسترول",
            ),
            # Once a month, on today's date: later today.
            (
                "فيتامين ب12", "1000", "mcg",
                {
                    **dose_at("21:00", "1", "tablet"),
                    "repeat": "monthly",
                    "weekdays": [],
                    "month_days": [min(self.today.day, 28)],
                },
                "نقص فيتامين ب12",
            ),
            # Every other day, from a week ago.
            (
                "أسبرين", "81", "mg",
                {
                    **dose_at("08:00", "1", "tablet"),
                    "repeat": "interval",
                    "weekdays": [],
                    "interval_days": 2,
                },
                "حماية القلب",
            ),
        )
        for name, strength, unit, schedule, reason in medicines:
            self.create(
                lina,
                circle,
                medicine(
                    name, strength, unit, "tablet", [schedule], week,
                    reason_for_use=reason,
                ),
                self.at(-8),
            )

    # Khaled's checks and visits.
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
