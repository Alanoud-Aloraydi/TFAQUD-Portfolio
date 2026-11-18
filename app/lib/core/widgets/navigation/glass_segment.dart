import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:flutter/material.dart';

/// One segment of a [GlassSegmentedControl]: its label, the optional live
/// count beside it and the tap that chooses it.
class GlassSegment extends StatelessWidget {
  const GlassSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppTokens tokens = context.tokens;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.touch - 2 * AppGlass.segmentInset,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: !enabled
                              ? tokens.textSecondary
                              : selected
                              ? AppSemanticColors.textPrimary
                              : tokens.textSecondary,
                          fontWeight: selected
                              ? AppTextTheme.bold
                              : AppTextTheme.medium,
                        ),
                      ),
                    ),
                    if (count case final count?) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text('$count', style: text.labelSmall),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
