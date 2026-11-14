import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_alert.dart';
import 'package:flutter/material.dart';

/// A tile under the patient card: an outline icon, its name and one line
/// on what it holds. Both tiles take the height of the taller one.
class CircleFeatureTile extends StatelessWidget {
  const CircleFeatureTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.attention = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Something here waits to be filled: a honey tile with the yellow «!».
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title، $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: attention
            ? AppSemanticColors.surfaceAttention
            : AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.m,
          side: attention
              ? const BorderSide(color: AppSemanticColors.borderAttention)
              : AppSurfaces.edge,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(icon, size: AppSizes.icon, color: iconColor),
                    if (attention) ...<Widget>[
                      const Spacer(),
                      const AttentionMark(),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(title, style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: attention
                      ? text.bodySmall?.copyWith(
                          color: context.tokens.warningText,
                        )
                      : text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
