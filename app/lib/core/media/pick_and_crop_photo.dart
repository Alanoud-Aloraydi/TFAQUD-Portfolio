import 'package:app/core/media/photo_crop_actions.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a photo from [source] and opens the crop page; returns the cropped
/// PNG bytes, or null when cancelled. A denied camera or library shows a
/// message instead of throwing.
Future<Uint8List?> pickAndCropPhoto(
  BuildContext context,
  PhotoSource source, {
  bool circle = false,
  bool frontCamera = false,
}) async {
  XFile? selected;
  try {
    selected = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      preferredCameraDevice: frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      maxWidth: 2048,
      imageQuality: 85,
    );
  } on PlatformException {
    if (context.mounted) {
      AppToast.show(context, 'photos.access_failed', kind: ToastKind.error);
    }
    return null;
  }
  if (selected == null || !context.mounted) return null;
  final bytes = await selected.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.of(context).push<Uint8List>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoCropPage(bytes: bytes, circle: circle),
    ),
  );
}

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
