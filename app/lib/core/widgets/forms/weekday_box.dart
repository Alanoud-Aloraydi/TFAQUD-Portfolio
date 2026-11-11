import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// One tappable box of the weekday selector: a day, or the whole week.
class WeekdayBox extends StatelessWidget {
  const WeekdayBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
    this.muted = false,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    onTap: onTap,
    label: semanticLabel ?? label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: AppSizes.button),
        decoration: BoxDecoration(
          color: selected
              ? (muted
                    ? AppSemanticColors.selectedSurface
                    : AppSemanticColors.actionPrimary)
              : AppSemanticColors.surfaceContent,
          border: Border.all(color: AppSemanticColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: FittedBox(child: Text(label)),
      ),
    ),
  );
}
