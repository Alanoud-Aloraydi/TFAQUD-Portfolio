"""Finding one emergency contact, and checking a new or changed one."""

from uuid import UUID

from app.errors import NotFound
from app.medical.checks import check_other, invalid
from app.models import CareCircle, EmergencyContact
from app.models.medical import CONTACT_RELATIONS


class ContactChecks:
    """Finds and checks contacts."""

    def _get_contact(
        self, patient: CareCircle, contact_id: UUID
    ) -> EmergencyContact:
        """A contact is only reachable through its own patient's circle."""
        contact = self.session.get(
            EmergencyContact,
            contact_id,
            with_for_update=True,
            populate_existing=True,
        )
        if contact is None or contact.care_circle_id != patient.id:
            raise NotFound("The emergency contact does not exist.")
        return contact

    @staticmethod
    def _check_contact(
        name: str, relation: str, relation_other: str | None
    ) -> tuple[str, str | None]:
        """The contact's trimmed name (1 to 50 characters) and the words of
        «أخرى», after checking the relation is one the app offers.
        """
        name = name.strip()
        if not name or len(name) > 50:
            raise invalid(
                "name", "invalid_name", "The name must be 1 to 50 characters."
            )
        if relation not in CONTACT_RELATIONS:
            raise invalid("relation", "unknown_choice", "Unknown relation.")
        return name, check_other("relation_other", [relation], relation_other)
