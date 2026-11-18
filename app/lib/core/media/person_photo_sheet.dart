import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:flutter/material.dart';

/// Opens the sheet where a person's photo or avatar is changed; saves through
/// [PrivatePhotoRepository] to [photoPath] / [avatarPath] and calls [onSaved].
Future<void> showPersonPhotoSheet(
  BuildContext context, {
  required String title,
  required String name,
  required String photoPath,
  required String avatarPath,
  String? avatarCode,
  bool frontCamera = false,
  VoidCallback? onSaved,
}) => showGlassSheet<void>(
  context,
  title: title,
  builder: (_) => PersonPhotoEditor(
    title: title,
    name: name,
    photoPath: photoPath,
    avatarPath: avatarPath,
    avatarCode: avatarCode,
    frontCamera: frontCamera,
    onSaved: onSaved,
  ),
);
