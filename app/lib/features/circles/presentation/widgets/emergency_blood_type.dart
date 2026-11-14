import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The blood type in a dark box: the small label over the type, left to
/// right. A dash while nobody entered it.
class EmergencyBloodType extends StatelessWidget {
  const EmergencyBloodType({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.onInkSupporting,
            ),
          ),
          Text(
            value ?? '—',
            textDirection: TextDirection.ltr,
            style: text.headlineMedium?.copyWith(
              color: AppSemanticColors.surfaceContent,
            ),
          ),
        ],
      ),
    );
  }
}
