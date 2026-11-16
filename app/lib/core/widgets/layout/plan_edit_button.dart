import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «✎ تعديل» beside the card's status, which opens the edit form. It keeps
/// its word, so it reads as something to press, but not the outlined
/// capsule of before: beside the status badge that put two pills on one
/// line, and the edit is the smaller errand of the two. The screen reader
/// hears what it edits ([tooltip]).
class PlanEditButton extends StatelessWidget {
  const PlanEditButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  final VoidCallback onPressed;

  /// What the button edits, for the screen reader: «تعديل بيانات الدواء».
  final String tooltip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
    child: TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        foregroundColor: AppSemanticColors.actionStrong,
      ),
      onPressed: onPressed,
      icon: const Icon(AppIcons.pencil, size: AppSizes.iconSmall),
      label: Text(context.tr('common.edit'), semanticsLabel: spoken(tooltip)),
    ),
  );
}
