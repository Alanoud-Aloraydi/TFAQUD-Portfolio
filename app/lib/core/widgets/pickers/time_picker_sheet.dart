import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:app/core/widgets/pickers/picker_wheel_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Asks for a time of day in a bottom sheet of 12-hour wheels; null when the
/// sheet is dismissed.
Future<TimeOfDay?> showTafaqodTimeSheet(
  BuildContext context, {
  required String title,
  required TimeOfDay initialTime,
}) => showModalBottomSheet<TimeOfDay>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  builder: (_) => _TimePickerSheet(title: title, initialTime: initialTime),
);

/// Renders the time picker sheet element of time picker sheet.
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
        height: AppSizes.pickerViewport,
        child: Row(
          children: [
            _Wheel(
              count: 60,
              initial: _minute,
              label: (index) => index.toString().padLeft(2, '0'),
              onSelected: (index) => _minute = index,
              position: WheelPosition.first,
            ),
            _Wheel(
              count: 12,
              initial: _hour - 1,
              label: (index) => '${index + 1}',
              onSelected: (index) => _hour = index + 1,
              position: WheelPosition.middle,
            ),
            _Wheel(
              count: 2,
              initial: _isPm ? 1 : 0,
              label: (index) =>
                  context.tr(index == 0 ? 'common.am' : 'common.pm'),
              onSelected: (index) => _isPm = index == 1,
              position: WheelPosition.last,
            ),
          ],
        ),
      ),
    );
  }
}

/// One wheel of the time picker sheet. It owns its scroll controller so a
/// rebuild of the sheet never resets the wheel, and releases it on dispose.
class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.count,
    required this.initial,
    required this.label,
    required this.onSelected,
    required this.position,
  });

  final int count;
  final int initial;
  final String Function(int) label;
  final ValueChanged<int> onSelected;
  final WheelPosition position;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker.builder(
        scrollController: _controller,
        itemExtent: PickerWheelStyle.itemExtent,
        childCount: widget.count,
        selectionOverlay: PickerWheelStyle.overlay(widget.position),
        onSelectedItemChanged: widget.onSelected,
        itemBuilder: (_, index) => PickerWheelStyle.item(widget.label(index)),
      ),
    );
  }
}
