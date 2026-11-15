"""Keeping one image per owner, replacements serialized."""

from uuid import UUID

from sqlalchemy.orm import Session

from app.errors import NotFound
from app.models import (
    Account,
    AccountPhoto,
    CareCircle,
    CareCirclePhoto,
    MedicationPlan,
    MedicationPlanPhoto,
)
from app.photos.validation import valid_photo

# Each owner kind: its own row, and the table of its photo.
_OWNERS = {
    "account": (Account, AccountPhoto),
    "patient": (CareCircle, CareCirclePhoto),
    "medication": (MedicationPlan, MedicationPlanPhoto),
}


class PhotoService:
    """Store one image per owner with serialized replacements."""

    def __init__(self, session: Session):
        """Work inside the caller's database session."""
        self.session = session

    def get(self, kind: str, owner_id: UUID):
        """Return the owner's image without exposing another owner."""
        _, table = _OWNERS[kind]
        return self.session.get(table, owner_id)

    def put(self, kind: str, owner_id: UUID, data: bytes) -> None:
        """Replace the image after locking the owner row."""
        valid_photo(data)
        self._lock_owner(kind, owner_id)
        photo = self.get(kind, owner_id)
        if photo is None:
            _, table = _OWNERS[kind]
            key = table.__table__.primary_key.columns.keys()[0]
            photo = table(**{key: owner_id}, data=data)
            self.session.add(photo)
        else:
            photo.data = data
        self.session.flush()

    def delete(self, kind: str, owner_id: UUID) -> None:
        """Remove an image but retain its owner."""
        self._lock_owner(kind, owner_id)
        photo = self.get(kind, owner_id)
        if photo is not None:
            self.session.delete(photo)
            self.session.flush()

    def _lock_owner(self, kind: str, owner_id: UUID) -> None:
        """Lock the owner's row (an account or a patient) so two uploads of one
        photo cannot run at once; 404 when there is no such owner.
        """
        model, _ = _OWNERS[kind]
        if self.session.get(model, owner_id, with_for_update=True) is None:
            raise NotFound()
