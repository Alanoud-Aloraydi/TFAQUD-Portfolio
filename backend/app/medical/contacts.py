"""Adding, changing and removing an emergency contact."""

from uuid import UUID

from app.errors import ValidationFailed
from app.medical.parts import MAX_EMERGENCY_CONTACTS
from app.models import EmergencyContact


class Contacts:
    """Changes the emergency contacts."""

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
