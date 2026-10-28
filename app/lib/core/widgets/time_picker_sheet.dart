import 'package:app/core/widgets/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showTafaqodTimeSheet(
  BuildContext context, {
  required String title,
  required TimeOfDay initialTime,
}) => showModalBottomSheet<TimeOfDay>(
  context: context,
  builder: (_) => _TimePickerSheet(title: title, initialTime: initialTime),
);

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.title, required this.initialTime});

  final String title;
  final TimeOfDay initialTime;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _hour = widget.initialTime.hourOfPeriod == 0
      ? 12
      : widget.initialTime.hourOfPeriod;
  late int _minute = widget.initialTime.minute;
  late bool _isPm = widget.initialTime.period == DayPeriod.pm;

  @override
  Widget build(BuildContext context) {
    return PickerSheetFrame(
      title: widget.title,
      confirmLabel: context.tr('common.confirm'),
      onConfirm: () => Navigator.pop(
        context,
        TimeOfDay(hour: (_hour % 12) + (_isPm ? 12 : 0), minute: _minute),
      ),
      child: SizedBox(
        height: 216,
        child: Row(
          children: [
            _Wheel(
              count: 12,
              initial: _hour - 1,
              label: (index) => '${index + 1}',
              onSelected: (index) => _hour = index + 1,
            ),
            _Wheel(
              count: 60,
              initial: _minute,
              label: (index) => index.toString().padLeft(2, '0'),
              onSelected: (index) => _minute = index,
            ),
            _Wheel(
              count: 2,
              initial: _isPm ? 1 : 0,
              label: (index) =>
                  context.tr(index == 0 ? 'common.am' : 'common.pm'),
              onSelected: (index) => _isPm = index == 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.count,
    required this.initial,
    required this.label,
    required this.onSelected,
  });

  final int count;
  final int initial;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker.builder(
        scrollController: FixedExtentScrollController(initialItem: initial),
        itemExtent: 44,
        childCount: count,
        onSelectedItemChanged: onSelected,
        itemBuilder: (_, index) => Center(child: Text(label(index))),
      ),
    );
  }
}
