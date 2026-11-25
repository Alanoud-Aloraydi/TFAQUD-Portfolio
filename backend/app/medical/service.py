"""The medical file service: the circle's medical file opened for reading
or for a change, the profile, and adding, changing and removing an
emergency contact, locked by circle like `CareService`."""

from uuid import UUID

from sqlalchemy import select

from app.care import CareService
from app.errors import NotFound, ValidationFailed
from app.medical.parts import (
    MAX_EMERGENCY_CONTACTS,
    MedicalProfile,
    check_other,
    invalid,
)
from app.medical.profile import ProfileChanges
from app.models import CareCircle, EmergencyContact
from app.models.medical import CONTACT_RELATIONS


class MedicalService(ProfileChanges, CareService):
    """Medical profile and emergency contacts, with circle-level locking."""

    # Opens the file and reads the contacts.
    def _open_for(self, actor_id: UUID, circle_id: UUID, *, lock: bool):
        """Check access to the circle's medical data and return the patient.

        Writers lock the account and then the circle, so two edits of the
        same circle run one after the other. Access is checked after the lock,
        because a manager may have left a moment before.
        """
        self._lock_accounts(actor_id)
        if lock:
            self._lock_circle(circle_id)
        circle = self.session.get(
            CareCircle, circle_id, populate_existing=True
        )
        if circle is None:
            raise NotFound("The care circle does not exist.")
        if circle.account_id != actor_id:
            self._require_manager(actor_id, circle_id)
        return circle

    def get_file(
        self, actor_id: UUID, circle_id: UUID
    ) -> tuple[CareCircle, MedicalProfile, list[EmergencyContact]]:
        """Return the patient, the health data and the contacts."""
        patient = self._open_for(actor_id, circle_id, lock=False)
        return patient, self._read_profile(patient), self._contacts(patient)

    def _contacts(self, patient: CareCircle) -> list[EmergencyContact]:
        """The patient's emergency contacts, the first added first."""
        return list(
            self.session.scalars(
                select(EmergencyContact)
                .where(EmergencyContact.care_circle_id == patient.id)
                .order_by(EmergencyContact.created_at, EmergencyContact.id)
            )
        )

    # Changes the emergency contacts.
    def add_contact(
        self,
        actor_id: UUID,
        circle_id: UUID,
        name: str,
        relation: str,
        relation_other: str | None,
        phone: str,
    ) -> EmergencyContact:
        """Add a contact. At most MAX_EMERGENCY_CONTACTS per patient."""
        # Check the contact, then lock the patient: at most five contacts, each
        # number once.
        name, relation_other = self._check_contact(
            name, relation, relation_other
        )
        patient = self._open_for(actor_id, circle_id, lock=True)
        contacts = self._contacts(patient)
        if len(contacts) >= MAX_EMERGENCY_CONTACTS:
            raise ValidationFailed(
                f"A patient can have at most {MAX_EMERGENCY_CONTACTS} "
                "emergency contacts.",
                code="too_many_contacts",
            )
        if any(contact.phone_number == phone for contact in contacts):
            raise ValidationFailed(
                "This phone number is already an emergency contact.",
                code="duplicate_contact",
            )
        contact = EmergencyContact(
            care_circle_id=patient.id,
            name=name,
            relation=relation,
            relation_other=relation_other,
            phone_number=phone,
        )
        self.session.add(contact)
        self.session.flush()
        self.session.refresh(contact)
        return contact

    def update_contact(
        self,
        actor_id: UUID,
        circle_id: UUID,
        contact_id: UUID,
        name: str,
        relation: str,
        relation_other: str | None,
        phone: str,
    ) -> EmergencyContact:
        """Replace name, relation and phone of one contact."""
        # Check the contact, lock the patient; the new number must not be
        # another contact's.
        name, relation_other = self._check_contact(
            name, relation, relation_other
        )
        patient = self._open_for(actor_id, circle_id, lock=True)
        contact = self._get_contact(patient, contact_id)
        if any(
            other.phone_number == phone and other.id != contact.id
            for other in self._contacts(patient)
        ):
            raise ValidationFailed(
                "This phone number is already an emergency contact.",
                code="duplicate_contact",
            )
        contact.name = name
        contact.relation = relation
        contact.relation_other = relation_other
        contact.phone_number = phone
        self.session.flush()
        return contact

    def delete_contact(
        self, actor_id: UUID, circle_id: UUID, contact_id: UUID
    ) -> None:
        """Remove one contact of this circle's patient."""
        patient = self._open_for(actor_id, circle_id, lock=True)
        self.session.delete(self._get_contact(patient, contact_id))
        self.session.flush()

    # Finds and checks contacts.
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
