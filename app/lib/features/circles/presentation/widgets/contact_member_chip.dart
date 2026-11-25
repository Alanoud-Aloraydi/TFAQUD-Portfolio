import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:flutter/material.dart';

/// One circle member to pick: their picture and name in a pill, marked when
/// the form holds their name and number.
class ContactMemberChip extends StatelessWidget {
  const ContactMemberChip({
    super.key,
    required this.choice,
    required this.circleId,
    required this.selected,
    this.onTap,
  });

  final ContactChoice choice;
  final String circleId;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected
          ? AppSemanticColors.selectedSurface
          : AppSemanticColors.surfaceContent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppSemanticColors.actionPrimary
              : AppSemanticColors.borderSubtle,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ContactChoicePhoto(choice: choice, circleId: circleId),
                const SizedBox(width: AppSpacing.sm),
                Text(choice.name),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The picture of a circle member inside the pill that picks them.
class ContactChoicePhoto extends StatelessWidget {
  const ContactChoicePhoto({
    super.key,
    required this.choice,
    required this.circleId,
  });

  /// Small enough to sit inside a pill the height of a touch area.
  static const double size = 32;

  final ContactChoice choice;
  final String circleId;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.capsule),
    child: PersonPhoto(
      name: choice.name,
      photoPath: choice.accountId == null
          ? ''
          : personPhotoPath(circleId, choice.accountId),
      avatarCode: choice.avatarCode,
      size: size,
    ),
  );
}
