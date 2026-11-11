import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/weekdays.dart';
import 'package:app/core/widgets/forms/weekday_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The days of the week a plan repeats on, for every kind of plan.
///
/// A wide «كل الأيام» button on top selects the whole week. While all seven
/// days are on, that button is the only highlighted thing and the seven
/// days below are muted; tapping a day then picks that day alone.
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WeekdayBox(
          label: context.tr('weekday_picker.all_days'),
          selected: every,
          onTap: () => onChanged(<int>{...allWeekdays}),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            for (final int day in weekOrder)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: WeekdayBox(
                    label: context.tr('medications.weekday_short.$day'),
                    semanticLabel: context.tr('medications.weekday.$day'),
                    selected: selected.contains(day),
                    muted: every,
                    onTap: () => onChanged(toggleWeekday(selected, day)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
