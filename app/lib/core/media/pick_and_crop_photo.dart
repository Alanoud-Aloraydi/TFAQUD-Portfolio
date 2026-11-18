import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/media/photo_source.dart';
import 'package:flutter/cupertino.dart';
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
