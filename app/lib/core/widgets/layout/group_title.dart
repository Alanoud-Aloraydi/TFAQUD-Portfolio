import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
