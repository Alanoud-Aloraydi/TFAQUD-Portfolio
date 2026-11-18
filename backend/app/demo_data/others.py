"""3. and 4.: Sara's grandfather, and what waits for an answer."""

from datetime import date

from app.care import CareService
from app.demo_data.shapes import dose_at, medicine
from app.demo_data.story import INVITED_PHONE, JEDDAH_POINT, REQUEST_PHONE
from app.errors import ValidationFailed
from app.models import CareCircle


class DemoOthers:
    """The grandfather and what waits."""

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
            *JEDDAH_POINT,
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
