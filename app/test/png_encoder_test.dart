import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:app/core/media/png_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// 64 x 48 pixels with every channel changing, and some see-through ones.
RgbaPixels _pixels() {
  const int width = 64;
  const int height = 48;
  final Uint8List rgba = Uint8List(width * height * 4);
  for (int i = 0; i < rgba.length; i++) {
    rgba[i] = (i * 37 + (i ~/ 256) * 11) & 0xff;
  }
  return (rgba: rgba, width: width, height: height);
}

int _u32(Uint8List bytes, int at) =>
    ByteData.sublistView(bytes, at, at + 4).getUint32(0);

void main() {
  test('writes an 8-bit RGBA PNG that decodes to the same pixels', () {
    final RgbaPixels pixels = _pixels();
    final Uint8List png = encodeRgbaPng(pixels);

    expect(png.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    // IHDR: 13 bytes, the size, 8 bits, colour type 6, no interlace.
    expect(_u32(png, 8), 13);
    expect(String.fromCharCodes(png.sublist(12, 16)), 'IHDR');
    expect(_u32(png, 16), 64);
    expect(_u32(png, 20), 48);
    expect(png.sublist(24, 29), <int>[8, 6, 0, 0, 0]);

    // IDAT follows; undo the Sub filter of each row.
    const int idat = 8 + 25;
    final int length = _u32(png, idat);
    expect(String.fromCharCodes(png.sublist(idat + 4, idat + 8)), 'IDAT');
    final List<int> rows = zlib.decode(
      png.sublist(idat + 8, idat + 8 + length),
    );
    const int stride = 64 * 4;
    final Uint8List decoded = Uint8List(stride * 48);
    for (int y = 0; y < 48; y++) {
      expect(rows[y * (stride + 1)], 1);
      for (int x = 0; x < stride; x++) {
        final int left = x < 4 ? 0 : decoded[y * stride + x - 4];
        decoded[y * stride + x] = (rows[y * (stride + 1) + 1 + x] + left) & 0xff;
      }
    }
    expect(decoded, pixels.rgba);

    // It ends with the standard IEND chunk and its well-known checksum.
    expect(
      png.sublist(png.length - 12),
      <int>[0, 0, 0, 0, 73, 69, 78, 68, 0xAE, 0x42, 0x60, 0x82],
    );
  });

  test('refuses pixels that do not match the size', () {
    expect(
      () => encodeRgbaPng((rgba: Uint8List(10), width: 64, height: 48)),
      throwsArgumentError,
    );
  });
}
