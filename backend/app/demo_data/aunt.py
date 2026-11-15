"""Lina's aunt in London, in her own zone."""

from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from app.care import CareService
from app.demo_data.shapes import dose_at, medicine
from app.demo_data.story import LONDON_POINT
from app.medications.plans import MedicationPlanService
from app.models import CareCircle


class DemoAunt:
    """The aunt's circle."""

    def aunt(self, lina) -> CareCircle:
        """6. Lina's aunt Huda, who lives in London and has no account.
        Her day is London's: an evening dose at 21:00 there, and a medicine
        the family stopped yesterday at 20:00 London time, so yesterday's
        21:00 dose of it is not a dose (the database checks it in her zone,
        not in Riyadh's)."""
        care = CareService(self.session, self.at(-14))
        circle = care.create_without_account(
            lina.id,
            "هدى",
            "العتيبي",
            date(1960, 2, 14),
            "لندن",
            *LONDON_POINT,
            time_zone="Europe/London",
        )
        self.create(
            lina,
            circle,
            medicine(
                "ليفوثيروكسين",
                "50",
                "mcg",
                "tablet",
                [dose_at("21:00", "1", "tablet")],
                self.day(-10),
                reason_for_use="الغدة الدرقية",
            ),
            self.at(-11),
        )
        stopped = self.create(
            lina,
            circle,
            medicine(
                "باراسيتامول",
                "500",
                "mg",
                "tablet",
                [dose_at("21:00", "1", "tablet")],
                self.day(-6),
                reason_for_use="الصداع",
            ),
            self.at(-7),
        )
        london = ZoneInfo("Europe/London")
        yesterday_evening = datetime.combine(
            self.now.astimezone(london).date() - timedelta(days=1),
            time(20, 0),
            tzinfo=london,
        )
        MedicationPlanService(self.session, yesterday_evening).stop(
            circle.id, stopped.id, lina.id
        )
        return circle
