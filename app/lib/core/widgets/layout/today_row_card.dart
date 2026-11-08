import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared card shell for one row of Today's schedule (a dose, a measurement
/// task, an appointment): same background, radius and padding, with the red
/// border shown when the row needs attention (late or missed).
class TodayRowCard extends StatelessWidget {
  const TodayRowCard({
    super.key,
    required this.child,
    this.isAttention = false,
  });

  final Widget child;
  final bool isAttention;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isAttention
            ? Theme.of(context).colorScheme.errorContainer
            : AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: isAttention ? Border.all(color: context.tokens.error) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}
