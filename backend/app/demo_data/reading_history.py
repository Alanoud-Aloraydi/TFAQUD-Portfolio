"""A month of pressure and sugar readings behind a plan."""


class DemoReadingHistory:
    """Records past readings."""

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
