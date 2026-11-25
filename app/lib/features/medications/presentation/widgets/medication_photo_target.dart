import 'dart:typed_data';

import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/photo_crop_actions.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// What the form shows for the medicine's photo and what a tap on it does:
/// the picture with the pencil badge, or the dashed frame with a camera.
class MedicationPhotoTarget extends StatelessWidget {
  const MedicationPhotoTarget({
    super.key,
    required this.bytes,
    required this.onChanged,
  });

  final Uint8List? bytes;
  final void Function(Uint8List? bytes, bool removed) onChanged;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = this.bytes;
    return GestureDetector(
      onTap: () => chooseMedicationPhoto(
        context,
        hasPhoto: bytes != null,
        onChanged: onChanged,
      ),
      child: Semantics(
        button: true,
        label: spoken(context.tr('photos.medication')),
        child: SizedBox(
          height: 196,
          width: double.infinity,
          child: bytes == null
              ? CustomPaint(
                  painter: MedicationPhotoBorder(),
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
                    const PhotoEditBadge(),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Asks where the medicine's photo comes from, then crops what was picked.
/// Removing reports no bytes and the removal, so the form knows to delete
/// the one already saved.
Future<void> chooseMedicationPhoto(
  BuildContext context, {
  required bool hasPhoto,
  required void Function(Uint8List? bytes, bool removed) onChanged,
}) async {
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
