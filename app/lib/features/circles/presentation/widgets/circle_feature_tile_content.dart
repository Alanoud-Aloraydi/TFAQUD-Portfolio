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
