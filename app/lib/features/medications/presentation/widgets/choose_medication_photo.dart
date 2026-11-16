import 'dart:typed_data';

import 'package:app/core/media/photo_source.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
