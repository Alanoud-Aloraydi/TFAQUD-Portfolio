import 'package:app/features/medications/presentation/widgets/ruler_mark.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
import 'package:app/features/medications/presentation/widgets/ruler_slider_semantics.dart';
import 'package:app/features/medications/presentation/widgets/ruler_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Holds the wheel's scroll position: the mark stands still and the numbers
/// move under it, so the position is the value.
class RulerPickerState extends State<RulerPicker> {
  static const double _height = 64;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: indexOf(widget.value));

  /// The wheel item that holds [value].
  int indexOf(int value) => (value - widget.min) ~/ widget.step;

  @override
  void didUpdateWidget(RulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int index = indexOf(widget.value);
    if (_controller.hasClients && _controller.selectedItem != index) {
      _controller.jumpToItem(index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    final int value = widget.min + index * widget.step;
    if (value == widget.value) return;
    HapticFeedback.selectionClick();
    widget.onChanged(value);
  }

  void _jump(int value) =>
      _controller.jumpToItem(indexOf(value.clamp(widget.min, widget.max)));

  @override
  Widget build(BuildContext context) {
    return RulerSliderSemantics(
      picker: widget,
      onJump: _jump,
      child: SizedBox(
        height: _height * widget.look.scale,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            RulerWheel(
              controller: _controller,
              picker: widget,
              lastIndex: indexOf(widget.max),
              onSelected: _select,
            ),
            RulerMark(look: widget.look),
          ],
        ),
      ),
    );
  }
}
