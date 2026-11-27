"""The demo story in the order it happened: 1. Lina's own care, 3. and 4.
Sara's grandfather and what waits for an answer, and Lina's aunt in
London, in her own zone."""

from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from app.care import CareService
from app.demo_data.story import (
    INVITED_PHONE,
    REQUEST_PHONE,
    Summary,
    dose_at,
    medicine,
)
from app.errors import ValidationFailed
from app.medications.plans import MedicationPlanService
from app.models import CareCircle


class DemoStory:
    """Builds the story."""

    def build(self) -> Summary:
        """Make the whole demo: Lina's own care; her mother's circle (no
        account, every kind of medicine); Sara's grandfather's circle, which
        Sara invites Lina to manage; a request waiting for Lina's father; and
        her uncle Khaled's circle in simplified mode.
        """
        lina, sara, khaled = self.accounts()
        care = CareService(self.session, self.at(-60))
        own = self._lina_own(lina, care)
        mother = self._mother(lina, care)
        revise_metformin = self._mother_daily(lina, mother)
        self._mother_weekly(lina, mother)
        aspirin = self._mother_courses(lina, mother)
        grandfather = self._grandfather(sara, lina)
        self._waiting(lina, mother)

        # The stop and the coming change first, so the dose history follows
        # them: the stopped medicine has no doses after it stopped.
        MedicationPlanService(self.session, self.at(-3, 15)).stop(
            mother.id, aspirin.id, lina.id
        )
        plan, later = revise_metformin
        self.revise(lina, mother, plan, 1, later, self.day(5), self.now)

        self.mother_checks(lina, mother)
        uncle = self.uncle(lina, sara, khaled)
        aunt = self.aunt(lina)

        # The doses of the past month.
        self.history(lina, own)
        self.history(lina, mother)
        self.history(sara, grandfather)
        self.history(lina, uncle)
        self.history(lina, aunt)

        self.summary.circles = [
            "رعايتي",
            "دائرة نورة",
            "دائرة عبدالله",
            "دائرة هدى",
            "دائرة خالد",
        ]
        return self.summary

    # Lina's own circle.
    def _lina_own(self, lina, care) -> CareCircle:
        """1. Lina's own care: two simple medicines."""
        own = care.create_self(
            lina.id, "رعايتي", date(1995, 4, 12), "الرياض"
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

    # The grandfather and what waits.
    def _grandfather(self, sara, lina) -> CareCircle:
        """3. Sara's grandfather in Jeddah. Sara invites Lina to manage it,
        so Lina's bell has an invitation to answer."""
        recent_care = CareService(self.session, self.at(-5))
        grandfather = recent_care.create_without_account(
            sara.id,
            "عبدالله",
            "القحطاني",
            date(1948, 1, 20),
            "جدة",
        )
        self.create(
            sara,
            grandfather,
            medicine(
                "وارفارين",
                "5",
                "mg",
                "tablet",
                [dose_at("19:00", "1", "tablet")],
                self.day(-5),
                reason_for_use="سيولة الدم",
            ),
            self.at(-5),
        )
        CareService(self.session, self.at(-1)).invite_manager(
            sara.id, grandfather.id, lina.phone_number
        )
        return grandfather

    def _waiting(self, lina, mother) -> None:
        """Lina's invitation to her sister, and her request to her father's
        number, both still waiting."""
        # Lina invited her sister to help with their mother two days ago;
        # the Circle tab shows it as a pending invitation.
        sister = CareService(self.session, self.at(-2)).invite_manager(
            lina.id, mother.id, INVITED_PHONE
        )
        sister.created_at = sister.last_sent_at

        # 4. Lina asked her father's number for a circle; it waits for him.
        # The team may have signed in with that number on the test server
        # and made its own circle: then nothing can be asked of it.
        try:
            CareService(self.session, self.at(-2)).request_creation(
                lina.id, REQUEST_PHONE, "simplified"
            )
        except ValidationFailed as refused:
            if refused.code != "patient_has_circle":
                raise

    # The aunt's circle.
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
