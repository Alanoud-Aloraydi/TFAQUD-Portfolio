import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// One emergency contact of the medical file: their picture (a circle
/// member's, else the first letter), the name with «متحقق» when the number
/// uses TFAQUD or «غير متحقق» when not, the relation and the number, and a
/// pencil that opens the form of the contact.
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
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
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
          ExcludeSemantics(
            child: contact.accountId != null || contact.avatarCode != null
                ? PersonPhoto(
                    name: contact.name,
                    photoPath: contact.accountId == null
                        ? ''
                        : personPhotoPath(circleId, contact.accountId),
                    avatarCode: contact.avatarCode,
                    size: 40,
                  )
                : CircleAvatar(
                    backgroundColor: AppSemanticColors.selectedSurface,
                    foregroundColor: AppSemanticColors.textPrimary,
                    child: Text(
                      contact.initial,
                      style: text.titleMedium?.copyWith(
                        color: AppSemanticColors.textPrimary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(contact.name, style: text.titleMedium),
                    // Words and an icon, never colour alone.
                    StatusBadge(
                      text: context.tr(
                        contact.verified
                            ? 'circles.contact_verified'
                            : 'circles.contact_unverified',
                      ),
                      tone: contact.verified
                          ? StatusTone.success
                          : StatusTone.muted,
                      icon: contact.verified
                          ? AppIcons.checkCircle
                          : AppIcons.warningCircle,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: <Widget>[
                    Text(
                      MedicalTexts.relation(context, contact),
                      style: text.bodyMedium?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                    Text(
                      MedicalTexts.phone(contact),
                      textDirection: TextDirection.ltr,
                      style: text.bodyMedium?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                AppIcons.pencil,
                color: AppSemanticColors.textPrimary,
              ),
              tooltip: context.tr(
                'circles.contact_edit_action',
                args: <String>[contact.name],
              ),
            ),
        ],
      ),
    );
  }
}
