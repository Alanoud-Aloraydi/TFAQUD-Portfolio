"""What a photo or an avatar must be to be kept."""

import zlib

from app.errors import ValidationFailed

MAX_PHOTO_BYTES = 4 * 1024 * 1024
AVATAR_CODES = frozenset((
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
))


def valid_photo(data: bytes) -> bytes:
    """Accept a complete, bounded PNG produced by the app's cropper."""
    # A size the app's cropper can make, and the PNG signature.
    if (not 33 <= len(data) <= MAX_PHOTO_BYTES
            or data[:8] != b"\x89PNG\r\n\x1a\n"):
        raise ValidationFailed(code="invalid_photo")

    # Walk the chunks: each has a length, a kind, its data and a checksum.
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
        # The first chunk is the header: 64 to 2048 pixels each way, 8-bit
        # colour (RGB or RGBA), standard compression, no interlacing.
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
        # Keep the image data; the end chunk must close the file exactly; an
        # unknown chunk the image needs (an upper-case first letter) is
        # refused.
        elif kind == b"IDAT":
            image_data.extend(chunk)
        elif kind == b"IEND":
            saw_end = length == 0 and end == len(data)
            break
        elif kind[0] & 0x20 == 0:
            break
        offset = end

    # Unpack the image data, no more than the header promises: every row is
    # there, nothing is left over, and each row's filter is a valid one.
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
