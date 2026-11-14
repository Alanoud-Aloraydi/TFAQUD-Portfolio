import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One fact on the patient card: a slate capsule with an outline icon, an
/// optional word and the value in ink.
class CircleFact extends StatelessWidget {
  const CircleFact({
    super.key,
    required this.icon,
    this.label,
    required this.value,
  });

  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: AppSizes.iconSmall,
            color: AppSemanticColors.textSupporting,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  if (label != null) TextSpan(text: '$label '),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppSemanticColors.textPrimary,
                      fontWeight: AppTextTheme.semibold,
                    ),
                  ),
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
