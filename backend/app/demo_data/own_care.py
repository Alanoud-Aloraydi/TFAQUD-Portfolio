"""1. Lina's own care."""

from datetime import date

from app.demo_data.shapes import dose_at, medicine
from app.demo_data.story import RIYADH_POINT
from app.models import CareCircle


class DemoOwnCare:
    """Lina's own circle."""

    def _lina_own(self, lina, care) -> CareCircle:
        """1. Lina's own care: two simple medicines."""
        own = care.create_self(
            lina.id, "رعايتي", date(1995, 4, 12), "الرياض", *RIYADH_POINT
        )
        self.medical(
            lina,
            own,
            {
                "blood_type": "O+",
                "conditions": {"status": "none"},
                "allergies": {"status": "none"},
            },
        )
        self.create(
            lina,
            own,
            medicine(
                "فيتامين د",
                "25",
                "mcg",
                "capsule",
                [dose_at("09:00", "1", "capsule")],
                self.day(-20),
                reason_for_use="نقص فيتامين د",
            ),
            self.at(-21),
        )
        self.create(
            lina,
            own,
            medicine(
                "أوميبرازول",
                "20",
                "mg",
                "capsule",
                [
                    dose_at(
                        "07:00", "1", "capsule", instructions="قبل الإفطار"
                    )
                ],
                self.day(-14),
                reason_for_use="حموضة المعدة",
            ),
            self.at(-15),
        )
        return own
