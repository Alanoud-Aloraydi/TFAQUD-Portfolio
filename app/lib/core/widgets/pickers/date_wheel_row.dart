import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/pickers/date_wheel.dart';
import 'package:app/core/widgets/pickers/date_wheel_ranges.dart';
import 'package:app/core/widgets/pickers/picker_wheel_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The three wheels of the date sheet: day, month and year, each with its
/// own list from [ranges]. [onSelected] says which one the person turned.
class DateWheelRow extends StatelessWidget {
  const DateWheelRow({
    super.key,
    required this.ranges,
    required this.day,
    required this.onSelected,
  });

  final DateWheelRanges ranges;
  final int day;
  final void Function({int? year, int? month, int? day}) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.pickerViewport,
      child: Row(
        children: <Widget>[
          DateWheel(
            values: ranges.days,
            selected: day,
            label: (int value) => '$value',
            onSelected: (int value) => onSelected(day: value),
            position: WheelPosition.first,
          ),
          DateWheel(
            values: ranges.months,
            selected: ranges.month,
            label: (int value) => context.tr('circles.months.$value'),
            onSelected: (int value) => onSelected(month: value),
            flex: 2,
            position: WheelPosition.middle,
          ),
          DateWheel(
            values: ranges.years,
            selected: ranges.year,
            label: (int value) => '$value',
            onSelected: (int value) => onSelected(year: value),
            position: WheelPosition.last,
          ),
        ],
      ),
    );
  }
}
