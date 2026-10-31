import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Welcome page picture: the brand mark inside four thin orbit rings, with
/// five small dots on the rings. Sizes are in logical pixels, taken from the
/// 390-wide design frame. Replace it with the exported logo asset when the
/// design team provides one.
class OrbitPainter extends CustomPainter {
  const OrbitPainter({required this.centerY});

  /// Vertical position of the brand mark, in pixels from the top of the area.
  final double centerY;

  // The panel is honey, so the orbit's accent dots are ink.
  static const Color _orange = AppColors.ink;
  static const Color _dotLight = AppColors.surface;
  static const Color _dotMuted = AppColors.leafTint;

  static const List<double> _ringRadii = <double>[66, 112, 158, 204];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, centerY);

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.ink.withValues(alpha: 0.12);
    for (final double radius in _ringRadii) {
      canvas.drawCircle(center, radius, ring);
    }

    void dot(Offset offset, double radius, Color color) {
      canvas.drawCircle(center + offset, radius, Paint()..color = color);
    }

    dot(const Offset(-63, -145), 9, _dotLight);
    dot(const Offset(129, -158), 8, _orange);
    dot(const Offset(98, 54), 9, _dotLight);
    dot(const Offset(-117, 107), 7, _orange);
    dot(const Offset(74, 190), 5.5, _dotMuted);

    // Brand mark: white disc with a soft shadow, an ink ring and a small
    // green dot on the ring (green stays a small accent).
    canvas.drawCircle(
      center + const Offset(0, 6),
      46,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, 46, Paint()..color = AppColors.surface);
    canvas.drawCircle(center, 22, Paint()..color = AppColors.ink);
    canvas.drawCircle(center, 14, Paint()..color = AppColors.surface);
    const Offset mark = Offset(16, -16);
    canvas.drawCircle(center + mark, 6.5, Paint()..color = AppColors.surface);
    canvas.drawCircle(center + mark, 5, Paint()..color = AppColors.leaf);
  }

  @override
  bool shouldRepaint(OrbitPainter oldDelegate) {
    return oldDelegate.centerY != centerY;
  }
}
