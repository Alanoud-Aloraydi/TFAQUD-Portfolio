import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shared «يحتاج انتباهك» yellow box: a warning icon, a title, an optional
/// item count, and [child] below — collapsible when [onToggle] is given.
class AttentionBox extends StatelessWidget {
  const AttentionBox({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.expanded = true,
    this.onToggle,
  });

  final String title;
  final Widget child;
  final int? count;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool collapsible = onToggle != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceAttention,
        border: Border.all(color: AppSemanticColors.borderAttention),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.m),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: collapsible ? AppSpacing.tight : 0,
              ),
              child: Row(
                children: [
                  const Icon(
                    TafaqodPhosphorIcons.warning,
                    color: AppSemanticColors.statusWarning,
                    size: 17,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppSemanticColors.statusWarning),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // A contrasting fill, not surfaceAttention: the badge
                    // would vanish against the box's own background.
                    CompactStatusBadge(
                      text: '$count',
                      background: AppSemanticColors.accentWarm,
                      foreground: AppSemanticColors.textPrimary,
                    ),
                  ],
                  if (collapsible) ...[
                    const Spacer(),
                    Text(
                      context.tr(
                        expanded
                            ? 'today_dashboard.hide_attention'
                            : 'today_dashboard.show_attention',
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      expanded
                          ? TafaqodPhosphorIcons.caretUp
                          : TafaqodPhosphorIcons.caretDown,
                      size: 16,
                      color: AppSemanticColors.statusWarning,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (collapsible)
            AnimatedCrossFade(
              duration: AppMotion.disclosure,
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: child,
              secondChild: const SizedBox(width: double.infinity),
            )
          else
            child,
        ],
      ),
    );
  }
}
