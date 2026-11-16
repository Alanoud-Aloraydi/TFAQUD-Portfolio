"""Lina's mother's medicines of some weekdays only."""

from app.demo_data.shapes import dose_at, medicine


class DemoMotherWeekly:
    """Her weekday medicines."""

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
