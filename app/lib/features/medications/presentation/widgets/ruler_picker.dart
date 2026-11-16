import 'package:app/features/medications/presentation/widgets/ruler_look.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker_state.dart';
import 'package:flutter/material.dart';

/// A whole number on a ruler that slides under a fixed mark: the number
/// under the mark is the value. It snaps to each mark with a light
/// selection haptic, the way a picker wheel does, and reads to VoiceOver as
/// a slider (swipe up or down to change it). Each mark is [step] apart
/// («نذكّرك كل» counts days one by one; «ذكّرني لاحقًا» goes 5 minutes at a
/// time).
///
/// The numbers grow in the reading direction: to the left in Arabic.
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    required this.valueLabel,
    this.step = 1,
    this.isMajor,
    this.tickLabel,
    this.look = const RulerLook(),
  }) : assert(min < max && value >= min && value <= max && step > 0);

  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

  /// What the slider sets, for VoiceOver: «عدد الأيام».
  final String semanticLabel;

  /// The value as said: «3 أيام».
  final String Function(int value) valueLabel;

  /// How far apart two marks are; [min], [max] and [value] are on them.
  final int step;

  /// Whether a value's mark is long; by default the first one and every
  /// fifth number.
  final bool Function(int value)? isMajor;

  /// The words under a long mark; by default the number.
  final String Function(int value)? tickLabel;

  /// Its sizes and colours; the detailed mode's by default.
  final RulerLook look;

  @override
  State<RulerPicker> createState() => RulerPickerState();
}
