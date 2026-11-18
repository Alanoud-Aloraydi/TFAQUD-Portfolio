import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/core/media/png_encoder.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/rendering.dart';

/// What [frame] shows, as a PNG [width] pixels wide; null when its pixels
/// cannot be read.
Future<Uint8List?> cropFramePng(
  RenderRepaintBoundary frame,
  double width,
) async {
  final image = await frame.toImage(pixelRatio: width / frame.size.width);
  RgbaPixels? pixels;
  try {
    // 8-bit sRGB pixels, then the app's own PNG: the engine's PNG of a
    // wide-colour iPhone image may not be one the server accepts.
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data != null) {
      pixels = (
        rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        width: image.width,
        height: image.height,
      );
    }
  } finally {
    image.dispose();
  }
  if (pixels == null) return null;
  return compute(encodeRgbaPng, pixels);
}
