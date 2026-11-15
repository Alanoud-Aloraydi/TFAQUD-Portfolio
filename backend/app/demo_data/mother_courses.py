"""Lina's mother's other medicines: weekdays only, coming, finished and
stopped."""

from app.demo_data.shapes import dose_at, medicine


class DemoMotherCourses:
    """Her other medicines."""

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
