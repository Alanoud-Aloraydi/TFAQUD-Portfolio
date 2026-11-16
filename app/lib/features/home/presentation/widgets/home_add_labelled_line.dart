import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A short line with a word in the middle, such as «إنشاء خطة».
class HomeAddLabelledLine extends StatelessWidget {
  const HomeAddLabelledLine({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color line = AppSemanticColors.textPrimary.withValues(alpha: 0.12);
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(height: AppSizes.divider, color: line),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
        ),
        Expanded(
          child: Divider(height: AppSizes.divider, color: line),
        ),
      ],
    );
  }
}
