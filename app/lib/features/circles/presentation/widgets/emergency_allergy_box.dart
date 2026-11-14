import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The allergy in a light red box with a red edge: it is what a helper must
/// not miss.
class EmergencyAllergyBox extends StatelessWidget {
  const EmergencyAllergyBox({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceDanger,
        shape: AppRadius.shape(
          AppRadius.s,
          side: const BorderSide(color: AppSemanticColors.borderDanger),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            AppIcons.warning,
            size: AppSizes.icon,
            color: AppSemanticColors.statusError,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: AppSemanticColors.statusError,
                  ),
                ),
                Text(
                  value,
                  style: text.headlineSmall?.copyWith(
                    color: AppSemanticColors.statusError,
                    fontWeight: AppTextTheme.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
