import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The account's photo with the small pencil badge on it. Tapping it opens
/// the sheet that takes or picks a new one; VoiceOver reads it as a button.
class AccountPhotoButton extends StatelessWidget {
  const AccountPhotoButton({
    required this.name,
    required this.avatarCode,
    required this.onSaved,
    super.key,
  });

  /// The name the sheet shows and the letter the avatar falls back to.
  final String name;
  final String? avatarCode;

  /// Called once a new photo is saved.
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken(context.tr('photos.edit_your_photo')),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showPersonPhotoSheet(
          context,
          title: context.tr('photos.your_photo'),
          name: name,
          photoPath: ApiEndpoints.accountPhoto,
          avatarPath: ApiEndpoints.accountAvatar,
          avatarCode: avatarCode,
          frontCamera: true,
          onSaved: onSaved,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PersonPhoto(
              name: name,
              photoPath: ApiEndpoints.accountPhoto,
              avatarCode: avatarCode,
              size: AppSizes.avatarLarge,
            ),
            const PhotoEditBadge(),
          ],
        ),
      ),
    );
  }
}
