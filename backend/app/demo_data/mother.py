"""2. Lina's mother, who has no account: her circle, her checks, and her
medicines (daily, some weekdays only, coming, finished and stopped)."""

from datetime import date

from app.demo_data.story import EVERY_DAY, dose_at, medicine
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
            lina.id, mother.id, "محمد العتيبي", "son", None, "+966500000011"
        )
        contacts.add_contact(
            lina.id, mother.id, "ريم العتيبي", "daughter", None,
            "+966500000012",
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

    # Her daily medicines.
    def _mother_daily(self, lina, mother):
        """Her daily medicines; answers the change of metformin that starts
        in five days, made after the stop below."""
        # Twice a day, with a change that starts in 5 days (a pending
        # revision): the evening dose becomes 2 tablets.
        metformin = medicine(
            "ميتفورمين",
            "500",
            "mg",
            "tablet",
            [
                dose_at("08:00", "1", "tablet", instructions="مع الإفطار"),
                dose_at("20:00", "1", "tablet", instructions="مع العشاء"),
            ],
            self.day(-45),
            reason_for_use="السكري",
        )
        plan = self.create(lina, mother, metformin, self.at(-46))
        later = dict(metformin)
        later["schedules"] = [
            dose_at("08:00", "1", "tablet", instructions="مع الإفطار"),
            dose_at("20:00", "2", "tablet", instructions="مع العشاء"),
        ]
        revise_metformin = (plan, later)

        # Revised 10 days ago: half a tablet became one tablet.
        amlodipine = medicine(
            "أملوديبين",
            "5",
            "mg",
            "tablet",
            [dose_at("09:00", "0.5", "tablet")],
            self.day(-40),
            reason_for_use="ضغط الدم",
        )
        plan = self.create(lina, mother, amlodipine, self.at(-41))
        self.revise(
            lina,
            mother,
            plan,
            1,
            {**amlodipine, "schedules": [dose_at("09:00", "1", "tablet")]},
            self.day(-10),
            self.at(-11),
        )

        # An injection, in units.
        self.create(
            lina,
            mother,
            medicine(
                "إنسولين لانتوس",
                "100",
                "unit/mL",
                "injection",
                [dose_at("22:00", "12", "unit", instructions="تحت الجلد")],
                self.day(-30),
                reason_for_use="السكري",
                missed_after_minutes=120,
            ),
            self.at(-31),
        )

        # A short course of syrup that ends in 4 days.
        self.create(
            lina,
            mother,
            medicine(
                "شراب الكحة",
                "15",
                "mg/5mL",
                "liquid",
                [
                    dose_at("13:00", "5", "mL"),
                    dose_at("21:00", "5", "mL"),
                ],
                self.day(-3),
                self.day(4),
                reason_for_use="الكحة",
                missed_after_minutes=30,
            ),
            self.at(-4),
        )
        return revise_metformin

    # Her weekday medicines.
    def _mother_weekly(self, lina, mother) -> None:
        """Her medicines of some weekdays only."""
        # Drops on three days of the week only (Sunday, Tuesday, Thursday).
        self.create(
            lina,
            mother,
            medicine(
                "قطرة العين",
                "0.5",
                "%",
                "drops",
                [dose_at("10:00", "2", "drop", days=[7, 2, 4])],
                self.day(-25),
                reason_for_use="جفاف العين",
            ),
            self.at(-26),
        )

        # An inhaler on Monday, Wednesday and Friday evenings.
        self.create(
            lina,
            mother,
            medicine(
                "فنتولين",
                "100",
                "mcg/dose",
                "inhaler",
                [dose_at("18:00", "2", "puff", days=[1, 3, 5])],
                self.day(-18),
                reason_for_use="ضيق التنفس",
            ),
            self.at(-19),
        )

    # Her other medicines.
    def _mother_courses(self, lina, mother):
        """Her other medicines: one coming, one finished, one stopped (the
        stopped one is answered)."""
        # Scheduled: starts in a week.
        self.create(
            lina,
            mother,
            medicine(
                "أوميغا 3",
                "1000",
                "mg",
                "capsule",
                [
                    dose_at(
                        "14:00", "1", "capsule", instructions="بعد الغداء"
                    )
                ],
                self.day(7),
            ),
            self.at(0, 8),
        )

        # Previous: a finished one-week course.
        self.create(
            lina,
            mother,
            medicine(
                "سيبروفلوكساسين",
                "500",
                "mg",
                "tablet",
                [
                    dose_at("08:00", "1", "tablet"),
                    dose_at("20:00", "1", "tablet"),
                ],
                self.day(-28),
                self.day(-22),
                reason_for_use="التهاب المسالك",
            ),
            self.at(-29),
        )

        # Stopped 3 days ago by the family.
        aspirin = self.create(
            lina,
            mother,
            medicine(
                "أسبرين",
                "81",
                "mg",
                "tablet",
                [dose_at("12:00", "1", "tablet")],
                self.day(-35),
                reason_for_use="سيولة الدم",
            ),
            self.at(-36),
        )
        return aspirin
