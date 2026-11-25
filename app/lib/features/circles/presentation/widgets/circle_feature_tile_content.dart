import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/attention_mark.dart';
import 'package:flutter/material.dart';

/// What a circle feature tile shows: the icon, with the yellow «!» across
/// from it when something waits to be filled, the name, and the line on
/// what the tile holds.
class CircleFeatureTileContent extends StatelessWidget {
  const CircleFeatureTileContent({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.attention,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: AppSizes.icon, color: iconColor),
            if (attention) ...<Widget>[const Spacer(), const AttentionMark()],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: attention
              ? text.bodySmall?.copyWith(color: context.tokens.warningText)
              : text.bodySmall,
        ),
      ],
    );
  }
}

/// A small white capsule with a line edge (32 points high); its tap area is
/// 48 points.
class CircleSmallAction extends StatelessWidget {
  const CircleSmallAction({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// False while another change of the members is on its way.
  final bool enabled;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, _height),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.padded,
        // A soft grey fill, no line, as the rest of the circle tab.
        backgroundColor: AppSemanticColors.background,
        side: BorderSide.none,
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
      child: Text(label),
    );
  }
}
