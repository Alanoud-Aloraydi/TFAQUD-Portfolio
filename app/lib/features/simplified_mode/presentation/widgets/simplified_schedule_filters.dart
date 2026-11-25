import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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

/// One kind to filter the schedule by: a pill, dark while it is the one
/// chosen.
class SimplifiedScheduleFilter extends StatelessWidget {
  const SimplifiedScheduleFilter({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: SimplifiedStyle.touch),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? SimplifiedColors.ink : SimplifiedColors.clear,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SimplifiedColors.control, width: 1.5),
          ),
          child: Text(
            label,
            style: SimplifiedStyle.head(
              SimplifiedStyle.caption,
              color: selected ? SimplifiedColors.surface : SimplifiedColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
