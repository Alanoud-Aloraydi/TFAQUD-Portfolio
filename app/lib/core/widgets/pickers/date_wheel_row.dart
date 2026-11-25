import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/utils/calendar_day.dart';
import 'package:app/core/widgets/pickers/date_wheel.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The three wheels of the date sheet: day, month and year, each with its
/// own list from [ranges], in its calendar. The columns keep their shares
/// in either calendar (a Hijri month's name is longer), so a switch only
/// changes the words. [onSelected] says which one the person turned.
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
            label: (int value) => context.tr(
              ranges.calendar == DateCalendar.hijri
                  ? 'calendar.hijri_months.$value'
                  : 'circles.months.$value',
            ),
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

/// The years, months and days a date wheel offers between [first] and
/// [last], for the chosen [year] and [month], all in [calendar]'s own
/// numbers.
class DateWheelRanges {
  const DateWheelRanges({
    required this.first,
    required this.last,
    required this.year,
    required this.month,
    required this.calendar,
  });

  final CalendarDay first;
  final CalendarDay last;
  final int year;
  final int month;
  final DateCalendar calendar;

  List<int> get years => <int>[
    for (int year = first.year; year <= last.year; year++) year,
  ];

  List<int> get months {
    final int from = year == first.year ? first.month : 1;
    final int to = year == last.year ? last.month : 12;
    return <int>[for (int month = from; month <= to; month++) month];
  }

  List<int> get days {
    final int from = year == first.year && month == first.month ? first.day : 1;
    final int to = year == last.year && month == last.month
        ? last.day
        : daysInCalendarMonth(year, month, calendar);
    return <int>[for (int day = from; day <= to; day++) day];
  }
}
