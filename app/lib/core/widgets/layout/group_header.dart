import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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

  /// How far a 17-point glyph's drawing sits inside its square.
  static const double _glyphMargin = 1.5;

  @override
  Widget build(BuildContext context) {
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
                if (icon case final IconData shown) ...<Widget>[
                  // The triangle sits inside its square: moved by that
                  // margin, its edge lines up with the cards under it.
                  Transform.translate(
                    offset: Offset(
                      Directionality.of(context) == TextDirection.rtl
                          ? _glyphMargin
                          : -_glyphMargin,
                      0,
                    ),
                    child: Icon(shown, color: ink, size: 17),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // The title takes the room, so «إخفاء» sits at the far
                // edge, over the cards' own edge.
                Expanded(
                  child: GroupTitle(
                    title: title,
                    count: count,
                    ink: ink,
                    countFill: countFill,
                  ),
                ),
                if (collapsible) FoldAffordance(expanded: expanded, ink: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A folding group's [title] and how many are inside ([count]), in [ink]
/// (the theme's own colour when null), the count on [countFill].
class GroupTitle extends StatelessWidget {
  const GroupTitle({
    super.key,
    required this.title,
    this.count,
    this.ink,
    this.countFill,
  });

  final String title;
  final int? count;
  final Color? ink;
  final Color? countFill;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Flexible(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ink),
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
    ],
  );
}

/// What tells a group it folds: «إظهار» or «إخفاء» and the caret that
/// turns. The word is there because a caret alone is a guess, and it is
/// read out as part of the header's one stop.
class FoldAffordance extends StatelessWidget {
  const FoldAffordance({super.key, required this.expanded, this.ink});

  final bool expanded;
  final Color? ink;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        context.tr(expanded ? 'common.hide' : 'common.show'),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      const SizedBox(width: AppSpacing.xs),
      Icon(
        expanded
            ? TafaqodPhosphorIcons.caretUp
            : TafaqodPhosphorIcons.caretDown,
        size: 16,
        color: ink,
      ),
    ],
  );
}
