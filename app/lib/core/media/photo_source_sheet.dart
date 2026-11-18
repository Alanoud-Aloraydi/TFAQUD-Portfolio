import 'package:app/core/media/photo_source.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Asks where a photo comes from: camera, library, and (when [canRemove])
/// remove. Returns null when closed.
Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  required String title,
  bool canRemove = false,
}) => showGlassSheet<PhotoSource>(
  context,
  title: title,
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(CupertinoIcons.camera),
        title: Text(context.tr('photos.camera')),
        onTap: () => Navigator.pop(sheetContext, PhotoSource.camera),
      ),
      ListTile(
        leading: const Icon(CupertinoIcons.photo),
        title: Text(context.tr('photos.library')),
        onTap: () => Navigator.pop(sheetContext, PhotoSource.library),
      ),
      if (canRemove)
        ListTile(
          leading: const Icon(CupertinoIcons.trash),
          title: Text(context.tr('photos.remove')),
          onTap: () => Navigator.pop(sheetContext, PhotoSource.remove),
        ),
    ],
  ),
);
