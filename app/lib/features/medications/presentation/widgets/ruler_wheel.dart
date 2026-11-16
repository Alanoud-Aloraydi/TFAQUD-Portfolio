import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
import 'package:app/features/medications/presentation/widgets/ruler_tick.dart';
import 'package:flutter/material.dart';

/// A wheel turned on its side: its first number on the start side, the next
/// ones toward the end. A wheel this large is flat, as a ruler is.
class RulerWheel extends StatelessWidget {
  const RulerWheel({
    super.key,
    required this.controller,
    required this.picker,
    required this.lastIndex,
    required this.onSelected,
  });

  /// The width of one number on the ruler.
  static const double tickWidth = 14;

  final FixedExtentScrollController controller;
  final RulerPicker picker;
  final int lastIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return RotatedBox(
      quarterTurns: rtl ? 1 : 3,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: tickWidth * picker.look.scale,
        diameterRatio: 1000,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: lastIndex + 1,
          builder: (BuildContext context, int index) {
            final int number = picker.min + index * picker.step;
            final bool major =
                picker.isMajor?.call(number) ??
                (number == 1 || number % 5 == 0);
            return RotatedBox(
              quarterTurns: rtl ? 3 : 1,
              child: RulerTick(
                look: picker.look,
                major: major,
                label: major
                    ? (picker.tickLabel?.call(number) ?? '$number')
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
