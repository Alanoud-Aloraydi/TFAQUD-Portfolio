import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/weekdays.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The days of the week a plan repeats on, for every kind of plan, in the
/// app's chip style: a «كل الأيام» chip that selects the whole week, then a
/// round chip for each day. While the whole week is on, tapping a day picks
/// that day alone.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool every = isEveryDay(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilterChip(
          label: Text(context.tr('weekday_picker.all_days')),
          selected: every,
          onSelected: (_) => onChanged(<int>{...allWeekdays}),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Four days, then three: a seven-box row leaves each name too
        // narrow to read.
        for (final List<int> row in <List<int>>[
          weekOrder.sublist(0, 4),
          weekOrder.sublist(4),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                for (final int day in row) ...<Widget>[
                  if (day != row.first) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: WeekdayBox(
                      label: context.tr('medications.weekday_pick.$day'),
                      semanticLabel: context.tr('medications.weekday.$day'),
                      selected: selected.contains(day),
                      onTap: () => onChanged(toggleWeekday(selected, day)),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// One day of the weekday selector: a round chip with the day's name,
/// drawn as the app's other chips are (an outline, the soft violet of
/// «كل الأيام» when it is on), 44 points high. Seven of them share the
/// row's width, so on a narrow phone a day is a little narrower than high.
class WeekdayBox extends StatelessWidget {
  const WeekdayBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    onTap: onTap,
    label: spoken(semanticLabel ?? label),
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: AppSizes.touch,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: selected
                ? AppSemanticColors.selectedSurface
                : AppSemanticColors.surfaceContent,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? AppSemanticColors.selectedSurface
                    : context.tokens.borderControl,
              ),
            ),
          ),
          child: Center(
            child: Text(label, style: Theme.of(context).chipTheme.labelStyle),
          ),
        ),
      ),
    ),
  );
}
