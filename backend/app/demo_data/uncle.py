"""5. Lina's uncle Khaled, the patient of his own circle in the simplified
mode."""

from app.care import CareService
from app.demo_data.story import RIYADH_POINT
from app.medical import MedicalService
from app.models import CareCircle


class DemoUncle:
    """Khaled's circle and file."""

    def uncle(self, lina, sara, khaled) -> CareCircle:
        """5. Lina's uncle Khaled, the patient of his own circle in the
        simplified mode, cared for by Lina and Sara. His day has a dose of
        each status (done, late, next, later), a weekly, a monthly and an
        every-other-day medicine, two measurements with their targets, and
        three appointments: one Lina goes to, one only Sara goes to (Lina's
        phone is not reminded of it), and one both go to.
        """
        circle = self._uncle_circle(lina, sara, khaled)
        self._uncle_medicines(lina, circle)
        self._uncle_measurements(lina, khaled, circle)
        self._uncle_visits(lina, sara, circle)
        return circle

    def _uncle_circle(self, lina, sara, khaled) -> CareCircle:
        """His circle, from Lina's request he accepted, with Sara invited,
        his file and a contact."""
        care = CareService(self.session, self.at(-10))
        request = care.request_creation(
            lina.id, khaled.phone_number, "simplified"
        )
        care.respond_creation(khaled.id, request.id, True)
        circle = care.complete_creation(
            khaled.id,
            request.id,
            khaled.birth_date,
            khaled.city,
            *RIYADH_POINT,
            name="صحتي",
        )
        invitation = care.invite_manager(
            lina.id, circle.id, sara.phone_number
        )
        care.respond_invitation(sara.id, invitation.id, True)
        self.medical(
            lina,
            circle,
            {
                "blood_type": "B+",
                "conditions": {
                    "status": "listed",
                    "codes": ["hypertension", "diabetes"],
                },
                "allergies": {
                    "status": "listed",
                    "medication": [],
                    "food": ["tree_nuts"],
                },
            },
        )
        MedicalService(self.session, self.at(-10)).add_contact(
            lina.id, circle.id, "فهد العتيبي", "son", None, "+966500000021"
        )
        return circle
