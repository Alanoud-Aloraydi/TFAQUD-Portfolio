"""2. Lina's mother, who has no account: her circle and her checks."""

from datetime import date

from app.demo_data.story import EVERY_DAY, RIYADH_POINT
from app.medical import MedicalService
from app.models import CareCircle


class DemoMother:
    """Her circle and measurements."""

    def _mother(self, lina, care) -> CareCircle:
        """2. Lina's mother, who has no account: her file and contacts."""
        mother = care.create_without_account(
            lina.id,
            "نورة",
            "العتيبي",
            date(1956, 8, 3),
            "الرياض",
            *RIYADH_POINT,
        )
        self.medical(
            lina,
            mother,
            {
                "blood_type": "A+",
                "conditions": {
                    "status": "listed",
                    "codes": ["diabetes", "hypertension"],
                },
                "allergies": {
                    "status": "listed",
                    "medication": ["penicillin"],
                    "food": [],
                },
            },
        )
        contacts = MedicalService(self.session, self.at(-60))
        contacts.add_contact(
            lina.id, mother.id, "محمد العتيبي", "son", "+966500000011"
        )
        contacts.add_contact(
            lina.id, mother.id, "ريم العتيبي", "daughter", "+966500000012"
        )
        return mother

    def mother_checks(self, lina, mother) -> None:
        """The detailed mode's measurement and appointment: Noura's blood
        pressure twice a day, and a visit Lina takes her to."""
        # Blood pressure twice a day, and an endocrinology visit in two days
        # that Lina takes her to.
        self.measure(lina, mother, {
            "kind": "blood_pressure",
            "times": [
                {"time_of_day": "08:00"},
                {"time_of_day": "20:00"},
            ],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
        })
        self.pressure_history(lina, mother)
        # Her sugar as well, so the detailed mode shows both charts and
        # both tables of the health summary.
        self.measure(lina, mother, {
            "kind": "glucose",
            "times": [
                {"time_of_day": "07:00", "measurement_state": "fasting"},
                {"time_of_day": "14:00", "measurement_state": "after_meal"},
            ],
            "weekdays": list(EVERY_DAY),
            "starts_on": self.today,
        })
        self.glucose_history(lina, mother)
        self.appointment(lina, mother, {
            "specialty": "الغدد الصماء",
            "kind": "follow_up",
            "scheduled_on": self.day(2),
            "time_of_day": "16:30",
            "place": "مستشفى الملك فهد",
            "companion_account_ids": [lina.id],
        })
