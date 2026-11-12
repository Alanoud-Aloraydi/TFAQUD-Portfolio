import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/weekdays.dart';
import 'package:app/core/widgets/forms/weekday_box.dart';
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
        Row(
          children: <Widget>[
            for (final int day in weekOrder) ...<Widget>[
              if (day != weekOrder.first) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: WeekdayBox(
                  label: context.tr('medications.weekday_short.$day'),
                  semanticLabel: context.tr('medications.weekday.$day'),
                  selected: selected.contains(day),
                  onTap: () => onChanged(toggleWeekday(selected, day)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
