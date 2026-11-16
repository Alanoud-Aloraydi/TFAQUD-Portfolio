import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
import 'package:flutter/material.dart';

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
