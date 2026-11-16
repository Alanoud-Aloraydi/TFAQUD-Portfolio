import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The line between two plans, from the start of their text.
class HomeAddRowDivider extends StatelessWidget {
  const HomeAddRowDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: AppSizes.divider,
    indent: AppSpacing.lg + AppSizes.avatar + AppSpacing.md,
    color: AppSemanticColors.textPrimary.withValues(alpha: 0.08),
  );
}
