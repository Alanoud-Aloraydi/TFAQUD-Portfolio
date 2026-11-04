"""Validate and persist private, cropped PNG photographs."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import NotFound, ValidationFailed
from app.models import Account, MedicationPlan, Patient, Photo

MAX_PHOTO_BYTES = 4 * 1024 * 1024
AVATAR_CODES = frozenset((
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
))
_OWNERS = {
    "account": (Account, Photo.account_id),
    "patient": (Patient, Photo.patient_id),
    "medication": (MedicationPlan, Photo.medication_plan_id),
}


def valid_photo(data: bytes) -> bytes:
    """Accept a bounded PNG with a plausible cropped canvas."""
    if (not 33 <= len(data) <= MAX_PHOTO_BYTES
            or data[:8] != b"\x89PNG\r\n\x1a\n"
            or data[12:16] != b"IHDR"
            or data[-12:-8] != b"\x00\x00\x00\x00"
            or data[-8:-4] != b"IEND"):
        raise ValidationFailed(code="invalid_photo")
    width = int.from_bytes(data[16:20], "big")
    height = int.from_bytes(data[20:24], "big")
    if not (64 <= width <= 2048 and 64 <= height <= 2048):
        raise ValidationFailed(code="invalid_photo")
    return data


class PhotoService:
    """Store one image per owner with serialized replacements."""

    def __init__(self, session: Session):
        self.session = session

    def get(self, kind: str, owner_id: UUID) -> Photo | None:
        """Return the owner's image without exposing another owner."""
        _, column = _OWNERS[kind]
        return self.session.scalar(select(Photo).where(column == owner_id))

    def put(self, kind: str, owner_id: UUID, data: bytes) -> None:
        """Replace the image after locking the owner row."""
        valid_photo(data)
        self._lock_owner(kind, owner_id)
        photo = self.get(kind, owner_id)
        if photo is None:
            field = (
                "medication_plan_id"
                if kind == "medication" else f"{kind}_id"
            )
            photo = Photo(**{field: owner_id}, data=data)
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
        model, _ = _OWNERS[kind]
        if self.session.get(model, owner_id, with_for_update=True) is None:
            raise NotFound()
