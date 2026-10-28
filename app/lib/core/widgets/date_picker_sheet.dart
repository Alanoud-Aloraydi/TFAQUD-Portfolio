import 'dart:math' as math;

import 'package:app/core/widgets/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showTafaqodDateSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showModalBottomSheet<DateTime>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _DatePickerSheet(
    title: title,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  ),
);

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final String title;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _year = widget.initialDate.year;
  late int _month = widget.initialDate.month;
  late int _day = widget.initialDate.day;

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  List<int> get _months {
    final first = _year == widget.firstDate.year ? widget.firstDate.month : 1;
    final last = _year == widget.lastDate.year ? widget.lastDate.month : 12;
    return [for (var month = first; month <= last; month++) month];
  }

  List<int> get _days {
    final first =
        _year == widget.firstDate.year && _month == widget.firstDate.month
        ? widget.firstDate.day
        : 1;
    final last =
        _year == widget.lastDate.year && _month == widget.lastDate.month
        ? widget.lastDate.day
        : _daysInMonth;
    return [for (var day = first; day <= last; day++) day];
  }

  void _select({int? year, int? month, int? day}) {
    setState(() {
      _year = year ?? _year;
      _month = month ?? _month;
      _month = _month.clamp(_months.first, _months.last);
      _day = day ?? _day;
      _day = _day.clamp(_days.first, _days.last);
    });
  }

  @override
  Widget build(BuildContext context) {
    final years = [
      for (
        var year = widget.firstDate.year;
        year <= widget.lastDate.year;
        year++
      )
        year,
    ];
    return PickerSheetFrame(
      title: widget.title,
      confirmLabel: context.tr('common.confirm'),
      onConfirm: () => Navigator.pop(context, DateTime(_year, _month, _day)),
      child: SizedBox(
        height: 216,
        child: Row(
          children: [
            _Wheel(
              values: _days,
              selected: _day,
              label: (value) => '$value',
              onSelected: (value) => _select(day: value),
            ),
            _Wheel(
              values: _months,
              selected: _month,
              label: (value) => context.tr('circles.months.$value'),
              onSelected: (value) => _select(month: value),
              flex: 2,
            ),
            _Wheel(
              values: years,
              selected: _year,
              label: (value) => '$value',
              onSelected: (value) => _select(year: value),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.flex = 1,
  });

  final List<int> values;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final index = math.max(0, values.indexOf(selected));
    return Expanded(
      flex: flex,
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: index),
        itemExtent: 44,
        onSelectedItemChanged: (index) => onSelected(values[index]),
        children: [
          for (final value in values) Center(child: Text(label(value))),
        ],
      ),
    );
  }
}
