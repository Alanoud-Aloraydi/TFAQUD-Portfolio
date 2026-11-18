import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/plan_fact_row.dart';
import 'package:flutter/material.dart';

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
