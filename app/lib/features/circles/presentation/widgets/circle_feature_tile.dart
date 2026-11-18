import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile_content.dart';
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
    return Semantics(
      button: true,
      label: spoken('$title، $subtitle'),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: attention
            ? AppSemanticColors.surfaceAttention
            : AppSemanticColors.surfaceContent,
        // Only a file that needs attention keeps a line, in its colour.
        shape: AppRadius.shape(
          AppRadius.m,
          side: attention
              ? const BorderSide(color: AppSemanticColors.borderAttention)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CircleFeatureTileContent(
              icon: icon,
              iconColor: iconColor,
              title: title,
              subtitle: subtitle,
              attention: attention,
            ),
          ),
        ),
      ),
    );
  }
}
