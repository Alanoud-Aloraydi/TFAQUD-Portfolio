import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
