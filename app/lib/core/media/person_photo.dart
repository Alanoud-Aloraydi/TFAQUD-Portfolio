import 'package:app/core/media/avatar_codes.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

export 'avatar_codes.dart';
export 'person_photo_sheet.dart';

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
