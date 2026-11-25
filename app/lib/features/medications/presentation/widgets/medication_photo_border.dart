import 'dart:typed_data';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// The medicine's own photo above whatever follows it, and nothing at all
/// while there is no photo: no empty frame on a page that only reads.
class MedicationPhotoBanner extends StatelessWidget {
  const MedicationPhotoBanner({
    super.key,
    required this.circleId,
    required this.planId,
    required this.height,
    required this.bottomGap,
  });

  final String circleId;
  final String planId;
  final double height;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return MedicationPhotoBuilder(
      circleId: circleId,
      planId: planId,
      builder: (context, bytes) => bytes == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: MedicationPhotoImage(bytes: bytes, height: height),
            ),
    );
  }
}

/// Displays the medication photo builder UI.
class MedicationPhotoBuilder extends StatelessWidget {
  const MedicationPhotoBuilder({
    super.key,
    required this.circleId,
    required this.planId,
    required this.builder,
  });

  final String circleId;
  final String planId;
  final Widget Function(BuildContext context, Uint8List? bytes) builder;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final path = MedicationEndpoints.medicationPhoto(circleId, planId);
    return ListenableBuilder(
      listenable: repository.changes,
      builder: (context, _) => FutureBuilder<Uint8List?>(
        future: repository.load(path),
        builder: (context, snapshot) => builder(context, snapshot.data),
      ),
    );
  }
}
