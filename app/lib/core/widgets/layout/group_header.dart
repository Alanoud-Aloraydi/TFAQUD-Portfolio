import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/layout/fold_affordance.dart';
import 'package:flutter/material.dart';

/// The line a folding group opens with: an optional [icon], the [title],
/// how many are inside, and «إظهار» or «إخفاء» with its caret. The whole
/// line is one stop for a screen reader and one button, so the person
/// never hunts for a small arrow.
///
/// Shared by «يحتاج انتباهك» and the folded groups of «السجل»: they are
/// the same thing in different words, and were the same code twice.
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.count,
    this.icon,
    this.ink,
    this.countFill,
  });

  final String title;
  final bool expanded;

  /// Null leaves the group always open, and the line is not a button.
  final VoidCallback? onToggle;
  final int? count;
  final IconData? icon;

  /// The title, the icon and the caret; the theme's own colour when null.
  final Color? ink;
  final Color? countFill;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool collapsible = onToggle != null;
    return MergeSemantics(
      child: Semantics(
        button: collapsible,
        expanded: collapsible ? expanded : null,
        onTap: onToggle,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, color: ink, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    title,
                    style: text.titleMedium?.copyWith(color: ink),
                  ),
                ),
                if (count != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  StatusPill(
                    text: '$count',
                    background: countFill ?? AppSemanticColors.selectedSurface,
                    foreground: AppSemanticColors.textPrimary,
                  ),
                ],
                if (collapsible) ...<Widget>[
                  const Spacer(),
                  FoldAffordance(expanded: expanded, ink: ink),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
