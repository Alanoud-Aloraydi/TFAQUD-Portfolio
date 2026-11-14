import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Draws the empty medication photo placeholder border.
class MedicationPhotoBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppSemanticColors.borderControlBase
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(AppRadius.m),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 12) {
        canvas.drawPath(metric.extractPath(start, start + 7), paint);
      }
    }
    final iconPaint = Paint()
      ..color = AppSemanticColors.textSupporting
      ..strokeWidth = 2;
    final center = Offset(size.width / 2 + 24, size.height / 2 - 16);
    canvas.drawLine(center.translate(-5, 0), center.translate(5, 0), iconPaint);
    canvas.drawLine(center.translate(0, -5), center.translate(0, 5), iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
