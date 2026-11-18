import 'package:app/core/widgets/pickers/date_wheel_ranges.dart';
import 'package:app/core/widgets/pickers/date_wheel_row.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The body of the date sheet. Every date in the app is picked with it.
///
/// In a right-to-left language the first wheel is on the right: day, month,
/// year, as an Arabic date is read. Numbers use the digits 0 to 9.
class DateWheelSheet extends StatefulWidget {
  const DateWheelSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.confirmLabel,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? confirmLabel;

  @override
  State<DateWheelSheet> createState() => _DateWheelSheetState();
}

class _DateWheelSheetState extends State<DateWheelSheet> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    // Start inside the allowed range, even if the caller's date is not.
    final DateTime start = widget.initialDate.isBefore(widget.firstDate)
        ? widget.firstDate
        : widget.initialDate.isAfter(widget.lastDate)
        ? widget.lastDate
        : widget.initialDate;
    _year = start.year;
    _month = start.month;
    _day = start.day;
  }

  DateWheelRanges get _ranges => DateWheelRanges(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    year: _year,
    month: _month,
  );

  /// Changing the year or the month can leave the day (or the month) out of
  /// range, such as 31 in a 30-day month; it moves back to the nearest one.
  void _select({int? year, int? month, int? day}) {
    setState(() {
      _year = year ?? _year;
      _month = (month ?? _month).clamp(
        _ranges.months.first,
        _ranges.months.last,
      );
      _day = (day ?? _day).clamp(_ranges.days.first, _ranges.days.last);
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateWheelRanges ranges = _ranges;
    return PickerSheetFrame(
      confirmLabel: widget.confirmLabel ?? context.tr('common.confirm'),
      onConfirm: () => Navigator.pop(context, DateTime(_year, _month, _day)),
      child: DateWheelRow(ranges: ranges, day: _day, onSelected: _select),
    );
  }
}
