"""Khaled's medicines: a dose of each status today."""

from app.demo_data.shapes import dose_at, medicine


class DemoUncleMedicines:
    """Khaled's medicines."""

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
