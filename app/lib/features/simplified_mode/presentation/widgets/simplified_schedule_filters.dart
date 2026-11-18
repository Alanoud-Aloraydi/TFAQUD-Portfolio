import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedScheduleFilters extends StatelessWidget {
  const SimplifiedScheduleFilters({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TodayTaskKind? selected;
  final ValueChanged<TodayTaskKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final Map<TodayTaskKind?, String> filters = <TodayTaskKind?, String>{
      null: context.tr('simplified_mode.filter.all'),
      TodayTaskKind.medication: context.tr('simplified_mode.filter.medication'),
      TodayTaskKind.measurement: context.tr(
        'simplified_mode.filter.measurement',
      ),
      TodayTaskKind.appointment: context.tr(
        'simplified_mode.filter.appointment',
      ),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final MapEntry<TodayTaskKind?, String> entry in filters.entries)
          SimplifiedScheduleFilter(
            label: entry.value,
            selected: entry.key == selected,
            onTap: () => onChanged(entry.key),
          ),
      ],
    );
  }
}
