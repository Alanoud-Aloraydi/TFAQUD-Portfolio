import 'dart:math' as math;

import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:flutter/cupertino.dart';

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
