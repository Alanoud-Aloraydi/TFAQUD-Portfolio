import 'dart:math' as math;

import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:app/core/widgets/pickers/picker_wheel_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Opens the app's one date picker: an iOS wheel of day, month and year with
/// one selection band across the row. Returns the confirmed date, or null
/// when the sheet is closed without confirming.
///
/// [confirmLabel] defaults to «تأكيد».
Future<DateTime?> showTafaqodDateSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? confirmLabel,
}) => showModalBottomSheet<DateTime>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => DateWheelSheet(
    title: title,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    confirmLabel: confirmLabel,
  ),
);

/// The body of the date sheet. Every date in the app is picked with it.
///
/// In a right-to-left language the first wheel is on the right: day, month,
/// year, as an Arabic date is read. Numbers use the digits 0 to 9.
class DateWheelSheet extends StatefulWidget {
  const DateWheelSheet({
    super.key,
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.confirmLabel,
  });

  final String title;
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

  List<int> get _years => <int>[
    for (int year = widget.firstDate.year; year <= widget.lastDate.year; year++)
      year,
  ];

  List<int> get _months {
    final int first = _year == widget.firstDate.year
        ? widget.firstDate.month
        : 1;
    final int last = _year == widget.lastDate.year ? widget.lastDate.month : 12;
    return <int>[for (int month = first; month <= last; month++) month];
  }

  List<int> get _days {
    final int first =
        _year == widget.firstDate.year && _month == widget.firstDate.month
        ? widget.firstDate.day
        : 1;
    final int last =
        _year == widget.lastDate.year && _month == widget.lastDate.month
        ? widget.lastDate.day
        : DateUtils.getDaysInMonth(_year, _month);
    return <int>[for (int day = first; day <= last; day++) day];
  }

  /// Changing the year or the month can leave the day (or the month) out of
  /// range, such as 31 in a 30-day month; it moves back to the nearest one.
  void _select({int? year, int? month, int? day}) {
    setState(() {
      _year = year ?? _year;
      _month = (month ?? _month).clamp(_months.first, _months.last);
      _day = (day ?? _day).clamp(_days.first, _days.last);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PickerSheetFrame(
      title: widget.title,
      confirmLabel: widget.confirmLabel ?? context.tr('common.confirm'),
      onConfirm: () => Navigator.pop(context, DateTime(_year, _month, _day)),
      child: SizedBox(
        height: AppSizes.pickerViewport,
        child: Row(
          children: <Widget>[
            _Wheel(
              values: _days,
              selected: _day,
              label: (int value) => '$value',
              onSelected: (int value) => _select(day: value),
              position: WheelPosition.first,
            ),
            _Wheel(
              values: _months,
              selected: _month,
              label: (int value) => context.tr('circles.months.$value'),
              onSelected: (int value) => _select(month: value),
              flex: 2,
              position: WheelPosition.middle,
            ),
            _Wheel(
              values: _years,
              selected: _year,
              label: (int value) => '$value',
              onSelected: (int value) => _select(year: value),
              position: WheelPosition.last,
            ),
          ],
        ),
      ),
    );
  }
}

/// One wheel. It keeps its own scroll controller, so the wheel being turned
/// is never rebuilt with a new one; when its list changes under it (fewer
/// days in the new month), it moves to the chosen value after the frame.
class _Wheel extends StatefulWidget {
  const _Wheel({
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
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _indexOf(widget.selected));

  int _indexOf(int value) => math.max(0, widget.values.indexOf(value));

  @override
  void didUpdateWidget(_Wheel oldWidget) {
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
