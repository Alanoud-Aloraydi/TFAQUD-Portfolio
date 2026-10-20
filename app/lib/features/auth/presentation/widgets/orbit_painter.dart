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

  static const Color _orange = Color(0xFFE9A23B);
  static const Color _dotLight = Color(0xFFE9EFF1);
  static const Color _dotMuted = Color(0xFFC1D5DB);

  static const List<double> _ringRadii = <double>[66, 112, 158, 204];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, centerY);

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.18);
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

    // Brand mark: white disc with a soft shadow, a teal ring and a small
    // orange dot on the ring.
    canvas.drawCircle(
      center + const Offset(0, 6),
      46,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, 46, Paint()..color = Colors.white);
    canvas.drawCircle(center, 22, Paint()..color = AppColors.brand);
    canvas.drawCircle(center, 14, Paint()..color = Colors.white);
    const Offset mark = Offset(16, -16);
    canvas.drawCircle(center + mark, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(center + mark, 5, Paint()..color = _orange);
  }

  @override
  bool shouldRepaint(OrbitPainter oldDelegate) {
    return oldDelegate.centerY != centerY;
  }
}
