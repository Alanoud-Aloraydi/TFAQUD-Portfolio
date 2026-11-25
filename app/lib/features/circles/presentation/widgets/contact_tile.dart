import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/widgets/contact_tile_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One emergency contact of the medical file: their picture, the name with
/// «متحقق» or «غير متحقق», the relation and the number, and a pencil that
/// opens the form of the contact.
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.circleId,
    this.onEdit,
  });

  final EmergencyContact contact;

  /// For a member's photo.
  final String circleId;

  /// Null hides the pencil (a form is open and one contact is edited at a
  /// time).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
    ),
    decoration: AppSurfaces.card(),
    child: Row(
      children: <Widget>[
        ContactTilePhoto(contact: contact, circleId: circleId),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: ContactTileLines(contact: contact)),
        if (onEdit case final VoidCallback edit)
          EditAction.pen(
            onPressed: edit,
            tooltip: context.tr(
              'circles.contact_edit_action',
              args: <String>[contact.name],
            ),
          ),
      ],
    ),
  );
}

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
