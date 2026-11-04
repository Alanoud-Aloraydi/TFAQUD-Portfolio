import 'dart:io' show zlib;
import 'dart:typed_data';

/// The pixels of a cropped photo: 8-bit RGBA, straight alpha, row after row.
typedef RgbaPixels = ({Uint8List rgba, int width, int height});

/// Encodes [pixels] as a plain PNG: 8 bits per channel, RGBA, no interlace,
/// one IDAT chunk. This is exactly what the server accepts
/// (`backend/app/photos.py`).
///
/// The app does not use the engine's PNG encoder: on an iPhone with wide
/// colour (Impeller), it may write a PNG the server refuses. These pixels
/// come from `toByteData(format: ImageByteFormat.rawStraightRgba)`, which
/// is always 8-bit sRGB.
///
/// Each row uses the Sub filter (the difference from the pixel before it),
/// which keeps photos much smaller than raw rows.
Uint8List encodeRgbaPng(RgbaPixels pixels) {
  final int width = pixels.width;
  final int height = pixels.height;
  final Uint8List rgba = pixels.rgba;
  final int stride = width * 4;
  if (width <= 0 || height <= 0 || rgba.length != stride * height) {
    throw ArgumentError('The pixels do not match $width x $height.');
  }

  final Uint8List rows = Uint8List((stride + 1) * height);
  for (int y = 0; y < height; y++) {
    final int from = y * stride;
    final int to = y * (stride + 1);
    rows[to] = 1; // Sub
    for (int x = 0; x < stride; x++) {
      final int left = x < 4 ? 0 : rgba[from + x - 4];
      rows[to + 1 + x] = (rgba[from + x] - left) & 0xff;
    }
  }

  final ByteData header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bits per channel
    ..setUint8(9, 6) // RGBA
    ..setUint8(10, 0) // deflate
    ..setUint8(11, 0) // adaptive filters
    ..setUint8(12, 0); // no interlace

  final BytesBuilder png = BytesBuilder(copy: false)
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(png, 'IHDR', header.buffer.asUint8List());
  _chunk(png, 'IDAT', Uint8List.fromList(zlib.encode(rows)));
  _chunk(png, 'IEND', Uint8List(0));
  return png.takeBytes();
}

void _chunk(BytesBuilder png, String type, Uint8List data) {
  final Uint8List kind = Uint8List.fromList(type.codeUnits);
  final ByteData length = ByteData(4)..setUint32(0, data.length);
  png
    ..add(length.buffer.asUint8List())
    ..add(kind)
    ..add(data);
  int crc = 0xffffffff;
  crc = _crc(crc, kind);
  crc = _crc(crc, data);
  final ByteData sum = ByteData(4)..setUint32(0, crc ^ 0xffffffff);
  png.add(sum.buffer.asUint8List());
}

final Uint32List _crcTable = () {
  final Uint32List table = Uint32List(256);
  for (int n = 0; n < 256; n++) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    table[n] = c;
  }
  return table;
}();

int _crc(int crc, Uint8List bytes) {
  int c = crc;
  for (final int byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  }
  return c;
}
