import 'package:app/core/widgets/pickers/picker_wheel_style.dart';
import 'package:flutter/cupertino.dart';

/// One wheel of the time picker sheet. It owns its scroll controller so a
/// rebuild of the sheet never resets the wheel, and releases it on dispose.
class TimeWheel extends StatefulWidget {
  const TimeWheel({
    super.key,
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
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
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
