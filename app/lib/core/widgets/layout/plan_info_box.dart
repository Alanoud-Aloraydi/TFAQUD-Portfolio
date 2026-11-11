import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The bordered box inside a plan or record card that groups what belongs
/// together: the times, the target, the place. Same radius and padding in
/// every card, so a medicine, a measurement and an appointment line up.
class PlanInfoBox extends StatelessWidget {
  const PlanInfoBox({super.key, required this.child, this.emphasis = false});

  final Widget child;

  /// A heavier border for a change that waits for later.
  final bool emphasis;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppSemanticColors.surfaceContent,
      border: Border.all(
        color: emphasis
            ? AppSemanticColors.textSupporting
            : AppSemanticColors.borderSubtle,
        width: emphasis ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(AppRadius.field),
    ),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}
