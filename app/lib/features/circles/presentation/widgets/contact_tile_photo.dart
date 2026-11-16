import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:flutter/material.dart';

/// The picture of an emergency contact: a circle member's, else the first
/// letter of their name. The name is read from the line beside it, so the
/// picture itself says nothing.
class ContactTilePhoto extends StatelessWidget {
  const ContactTilePhoto({
    super.key,
    required this.contact,
    required this.circleId,
  });

  final EmergencyContact contact;
  final String circleId;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: contact.accountId != null || contact.avatarCode != null
        ? PersonPhoto(
            name: contact.name,
            photoPath: contact.accountId == null
                ? ''
                : personPhotoPath(circleId, contact.accountId),
            avatarCode: contact.avatarCode,
            size: AppSizes.avatar,
          )
        : CircleAvatar(
            backgroundColor: AppSemanticColors.selectedSurface,
            foregroundColor: AppSemanticColors.textPrimary,
            child: Text(
              contact.initial,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppSemanticColors.textPrimary),
            ),
          ),
  );
}
