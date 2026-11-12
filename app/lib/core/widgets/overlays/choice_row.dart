import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One choice of a list in a sheet, as an iOS list row: its words, and a
/// check mark at the end of the chosen one. Every sheet that offers a list
/// of choices (a skip reason, a unit) uses this row.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 0,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.sm,
    ),
    onTap: onTap,
    selected: selected,
    title: Text(label),
    trailing: selected
        ? const Icon(AppIcons.check, color: AppSemanticColors.textPrimary)
        : null,
  );
}
