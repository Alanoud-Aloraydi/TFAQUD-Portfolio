import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/layout/expand_reveal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Records gathered under a heading that folds away, as «يحتاج انتباهك»
/// does: [title], [count], «إخفاء» or «عرض», all one button; then [child].
class CollapsibleGroup extends StatelessWidget {
  const CollapsibleGroup({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MergeSemantics(
            child: Semantics(
              button: true,
              expanded: expanded,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppRadius.m),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSizes.touch),
                  child: Row(
                    children: <Widget>[
                      Flexible(child: Text(title, style: text.titleMedium)),
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        text: '$count',
                        background: AppSemanticColors.selectedSurface,
                        foreground: AppSemanticColors.textPrimary,
                      ),
                      const Spacer(),
                      Text(
                        context.tr(expanded ? 'common.hide' : 'common.show'),
                        style: text.labelSmall,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        expanded
                            ? TafaqodPhosphorIcons.caretUp
                            : TafaqodPhosphorIcons.caretDown,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ExpandReveal(
            open: expanded,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
