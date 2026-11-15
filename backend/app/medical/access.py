"""Opening a circle's medical file for reading or for a change."""

from uuid import UUID

from sqlalchemy import select

from app.errors import NotFound
from app.medical.parts import MedicalProfile
from app.models import CareCircle, EmergencyContact


class MedicalAccess:
    """Opens the file and reads the contacts."""

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
