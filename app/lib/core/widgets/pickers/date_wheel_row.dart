import 'dart:math' as math;

import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/utils/calendar_day.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

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

/// One wheel. It keeps its own scroll controller, so the wheel being turned
/// is never rebuilt with a new one; when its list changes under it (fewer
/// days in the new month), it moves to the chosen value after the frame.
class DateWheel extends StatefulWidget {
  const DateWheel({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    required this.position,
    this.flex = 1,
  });

  final List<int> values;
  final int selected;
  final String Function(int value) label;
  final ValueChanged<int> onSelected;
  final WheelPosition position;
  final int flex;

  @override
  State<DateWheel> createState() => _DateWheelState();
}

class _DateWheelState extends State<DateWheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _indexOf(widget.selected));

  int _indexOf(int value) => math.max(0, widget.values.indexOf(value));

  @override
  void didUpdateWidget(DateWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int wanted = _indexOf(widget.selected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_controller.selectedItem != wanted) _controller.jumpToItem(wanted);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: PickerWheelStyle.itemExtent,
        selectionOverlay: PickerWheelStyle.overlay(widget.position),
        onSelectedItemChanged: (int index) {
          if (index >= 0 && index < widget.values.length) {
            widget.onSelected(widget.values[index]);
          }
        },
        children: <Widget>[
          for (final int value in widget.values)
            PickerWheelStyle.item(widget.label(value)),
        ],
      ),
    );
  }
}
