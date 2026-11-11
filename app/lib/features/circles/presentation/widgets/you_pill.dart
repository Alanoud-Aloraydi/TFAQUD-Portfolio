import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «أنت»: a small ink capsule after the viewer's name.
class YouPill extends StatelessWidget {
  const YouPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: StadiumBorder(),
      ),
      child: Text(
        context.tr('circle_overview.you'),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppSemanticColors.surfaceContent),
      ),
    );
  }
}
