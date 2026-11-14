import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:flutter/material.dart';

/// The avatars the server accepts as a person's picture (`assets/avatars`).
const avatarCodes = <String>[
  'w1_1',
  'w1_3',
  'w6_1',
  'w6_3',
  'm1_1',
  'm1_3',
  'm2_1',
  'm2_3',
  'm6_1',
  'm6_3',
  'w7_1',
  'w7_3',
];

/// A person's round photo: the uploaded photo, else their chosen avatar,
/// else the first letter of [name].
class PersonPhoto extends StatelessWidget {
  const PersonPhoto({
    super.key,
    required this.name,
    required this.photoPath,
    required this.size,
    this.avatarCode,
  });

  final String name;
  final String photoPath;
  final String? avatarCode;

  /// The width and the height: the photo is always a circle.
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = avatarCode;
    final photoWidth = size;
    final fallback = ClipOval(
      child: code != null && avatarCodes.contains(code)
          ? Image.asset(
              'assets/avatars/$code.png',
              width: photoWidth,
              height: size,
              fit: BoxFit.cover,
            )
          : Container(
              width: photoWidth,
              height: size,
              alignment: Alignment.center,
              color: AppSemanticColors.selectedSurface,
              child: Text(
                name.trim().isEmpty ? '؟' : name.trim().characters.first,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
    );
    if (photoPath.isEmpty) return fallback;
    return ClipOval(
      child: PrivatePhoto(
        path: photoPath,
        height: size,
        width: photoWidth,
        radius: size / 2,
        openViewer: false,
        fallback: fallback,
      ),
    );
  }
}

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
