import 'dart:typed_data';

import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_camera_badge.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// The photo being edited, with the camera badge that opens the choices:
/// the photo just picked ([selected]), the first letter once [removed], or
/// the saved photo or avatar.
class PersonPhotoPreview extends StatelessWidget {
  const PersonPhotoPreview({
    super.key,
    required this.name,
    required this.photoPath,
    required this.avatarCode,
    required this.selected,
    required this.removed,
    required this.code,
    required this.onTap,
  });

  final String name;
  final String photoPath;

  /// The avatar saved before this edit.
  final String? avatarCode;
  final Uint8List? selected;
  final bool removed;

  /// The avatar chosen now.
  final String? code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Uint8List? picked = selected;
    final preview = picked != null
        ? ClipOval(
            child: Image.memory(
              picked,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          )
        : removed
        ? CircleAvatar(
            radius: 48,
            backgroundColor: AppSemanticColors.selectedSurface,
            child: Text(name.isEmpty ? '؟' : name.characters.first),
          )
        : PersonPhoto(
            name: name,
            photoPath: code == avatarCode ? photoPath : '',
            avatarCode: code,
            size: 96,
          );
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppSemanticColors.borderSubtle),
                ),
                child: preview,
              ),
              const PositionedDirectional(
                bottom: 0,
                end: 0,
                child: PhotoCameraBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
