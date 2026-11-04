"""Validate and persist private, cropped PNG photographs."""

import zlib
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
    """Accept a complete, bounded PNG produced by the app's cropper."""
    if (not 33 <= len(data) <= MAX_PHOTO_BYTES
            or data[:8] != b"\x89PNG\r\n\x1a\n"):
        raise ValidationFailed(code="invalid_photo")

    offset = 8
    width = height = channels = 0
    image_data = bytearray()
    saw_header = saw_end = False
    while offset + 12 <= len(data):
        length = int.from_bytes(data[offset:offset + 4], "big")
        end = offset + 12 + length
        if end > len(data):
            break
        kind = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + length]
        checksum = int.from_bytes(data[end - 4:end], "big")
        if zlib.crc32(kind + chunk) != checksum:
            break
        if not saw_header:
            if kind != b"IHDR" or length != 13:
                break
            width = int.from_bytes(chunk[:4], "big")
            height = int.from_bytes(chunk[4:8], "big")
            if (not 64 <= width <= 2048 or not 64 <= height <= 2048
                    or chunk[8] != 8 or chunk[9] not in (2, 6)
                    or chunk[10:] != b"\x00\x00\x00"):
                break
            channels = 3 if chunk[9] == 2 else 4
            saw_header = True
        elif kind == b"IDAT":
            image_data.extend(chunk)
        elif kind == b"IEND":
            saw_end = length == 0 and end == len(data)
            break
        elif kind[0] & 0x20 == 0:
            break
        offset = end

    if not saw_header or not saw_end or not image_data:
        raise ValidationFailed(code="invalid_photo")
    expected = height * (1 + width * channels)
    try:
        decoder = zlib.decompressobj()
        pixels = decoder.decompress(image_data, expected + 1)
    except zlib.error as exc:
        raise ValidationFailed(code="invalid_photo") from exc
    if (len(pixels) != expected or not decoder.eof
            or decoder.unused_data or decoder.unconsumed_tail
            or any(pixels[row * (1 + width * channels)] > 4
                   for row in range(height))):
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
