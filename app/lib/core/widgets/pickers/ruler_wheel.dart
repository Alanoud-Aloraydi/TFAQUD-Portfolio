import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
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

/// The ruler as VoiceOver meets it: one slider that says what it sets and
/// what the next and previous values are, with the ruler itself excluded,
/// since a row of marks has nothing to read.
class RulerSliderSemantics extends StatelessWidget {
  const RulerSliderSemantics({
    super.key,
    required this.picker,
    required this.onJump,
    required this.child,
  });

  final RulerPicker picker;
  final ValueChanged<int> onJump;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int value = picker.value;
    final int step = picker.step;
    return Semantics(
      container: true,
      slider: true,
      label: spoken(picker.semanticLabel),
      value: picker.valueLabel(value),
      increasedValue: value < picker.max
          ? picker.valueLabel(value + step)
          : null,
      decreasedValue: value > picker.min
          ? picker.valueLabel(value - step)
          : null,
      onIncrease: value < picker.max ? () => onJump(value + step) : null,
      onDecrease: value > picker.min ? () => onJump(value - step) : null,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// One mark: a long one with its words under it, or a short one between.
class RulerTick extends StatelessWidget {
  const RulerTick({
    super.key,
    required this.major,
    this.label,
    this.look = const RulerLook(),
  });

  final bool major;
  final String? label;
  final RulerLook look;

  @override
  Widget build(BuildContext context) {
    final double scale = look.scale;
    final TextStyle words =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    return Column(
      children: <Widget>[
        Container(
          width: (major ? 2 : 1) * scale,
          height: (major ? 26 : 14) * scale,
          color: major ? look.major : look.minor,
        ),
        const Spacer(),
        // A number is wider than its mark: it overflows to both sides.
        SizedBox(
          height: 18 * scale,
          child: label != null
              ? OverflowBox(
                  maxWidth: 40 * scale,
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: words.copyWith(
                      color: look.label,
                      fontSize: (words.fontSize ?? 11) * scale,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
