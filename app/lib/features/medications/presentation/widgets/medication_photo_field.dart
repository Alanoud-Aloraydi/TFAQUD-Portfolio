import 'dart:typed_data';

import 'package:app/core/media/private_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the medication photo field UI.
class MedicationPhotoField extends StatelessWidget {
  const MedicationPhotoField({
    super.key,
    required this.circleId,
    required this.planId,
    required this.photo,
    required this.removed,
    required this.onChanged,
  });

  final String circleId;
  final String? planId;
  final Uint8List? photo;
  final bool removed;
  final void Function(Uint8List? bytes, bool removed) onChanged;

  @override
  Widget build(BuildContext context) {
    final path = planId == null
        ? null
        : ApiEndpoints.medicationPhoto(circleId, planId!);
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            context.tr('photos.medication'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        FutureBuilder<Uint8List?>(
          future: path == null ? null : repository.load(path),
          builder: (context, snapshot) {
            final bytes = removed ? null : photo ?? snapshot.data;
            return GestureDetector(
              onTap: () => _choose(context, bytes != null),
              child: Semantics(
                button: true,
                label: context.tr('photos.medication'),
                child: SizedBox(
                  height: 196,
                  width: double.infinity,
                  child: bytes == null
                      ? CustomPaint(
                          painter: _PhotoBorder(),
                          child: const Center(
                            child: Icon(CupertinoIcons.camera, size: 30),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              child: Image.memory(bytes, fit: BoxFit.cover),
                            ),
                            PositionedDirectional(
                              top: AppSpacing.sm,
                              end: AppSpacing.sm,
                              child: CircleAvatar(
                                backgroundColor:
                                    AppSemanticColors.surfaceContent,
                                child: const Icon(CupertinoIcons.pencil),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, bool hasPhoto) async {
    final source = await showPhotoSourceSheet(
      context,
      title: context.tr('photos.medication'),
      canRemove: hasPhoto,
    );
    if (source == null || !context.mounted) return;
    if (source == PhotoSource.remove) {
      onChanged(null, true);
      return;
    }
    final bytes = await pickAndCropPhoto(context, source);
    if (bytes != null) onChanged(bytes, false);
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
    final path = ApiEndpoints.medicationPhoto(circleId, planId);
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) => FutureBuilder<Uint8List?>(
        future: repository.load(path),
        builder: (context, snapshot) => builder(context, snapshot.data),
      ),
    );
  }
}

/// Displays the medication photo image UI.
class MedicationPhotoImage extends StatelessWidget {
  const MedicationPhotoImage({
    super.key,
    required this.bytes,
    required this.height,
    this.width = double.infinity,
    this.radius = AppRadius.m,
  });

  final Uint8List bytes;
  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => openPhotoViewer(context, bytes),
    child: Semantics(
      button: true,
      label: context.tr('photos.enlarge'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    ),
  );
}

/// Draws the empty medication photo placeholder border.
class _PhotoBorder extends CustomPainter {
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
