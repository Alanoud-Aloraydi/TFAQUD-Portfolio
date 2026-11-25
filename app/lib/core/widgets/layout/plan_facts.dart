import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/plan_fact_row.dart';
import 'package:flutter/material.dart';

export 'package:app/core/widgets/layout/plan_fact_group.dart';

/// A person: photo or avatar, then [label] («أضافه», none under a title that
/// says it) and the name in bold. Every name the app shows has its picture.
class PlanPersonFact extends StatelessWidget {
  const PlanPersonFact({
    super.key,
    this.label,
    required this.name,
    required this.circleId,
    this.accountId,
    this.avatarCode,
  });

  final String? label;
  final String name;
  final String circleId;
  final String? accountId;
  final String? avatarCode;

  @override
  Widget build(BuildContext context) => PlanFactRow(
    leading: PersonPhoto(
      name: name,
      // No account (an old plan): the avatar or the first letter, never
      // the patient's photo.
      photoPath: accountId == null ? '' : personPhotoPath(circleId, accountId),
      avatarCode: avatarCode,
      size: planFactLeadingSize,
    ),
    label: label,
    value: name,
  );
}

/// One fact: an icon tile, a small grey [label] and the [value] in bold,
/// so the value is what stands out. [trailing] sits at the end (a dose,
/// a state); [below] under the value (the days of the week).
class PlanFact extends StatelessWidget {
  const PlanFact({
    super.key,
    required this.icon,
    this.label,
    this.value,
    this.trailing,
    this.below,
  });

  final IconData icon;
  final String? label;
  final String? value;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) => PlanFactRow(
    leading: ExcludeSemantics(
      child: Container(
        width: planFactLeadingSize,
        height: planFactLeadingSize,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: AppSemanticColors.selectedSurface,
          shape: AppRadius.shape(AppRadius.xs * 2),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.textPrimary,
        ),
      ),
    ),
    label: label,
    value: value,
    trailing: trailing,
    below: below,
  );
}
