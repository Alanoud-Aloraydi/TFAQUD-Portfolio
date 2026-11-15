import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «✎ تعديل» beside the card's status, which opens the edit form: an
/// outlined button with its word, not a bare pencil, so it reads as
/// something to press. The screen reader hears what it edits ([tooltip]).
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
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      onPressed: onPressed,
      icon: const Icon(AppIcons.pencil, size: AppSizes.iconSmall),
      label: Text(context.tr('common.edit'), semanticsLabel: spoken(tooltip)),
    ),
  );
}
