"""Lina's mother's daily medicines."""

from app.demo_data.shapes import dose_at, medicine


class DemoMotherDaily:
    """Her daily medicines."""

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
