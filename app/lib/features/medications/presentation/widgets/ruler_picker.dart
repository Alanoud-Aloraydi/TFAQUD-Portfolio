import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  /// The width of one number on the ruler.
  static const double _step = 14;
  static const double _height = 64;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _indexOf(widget.value));

  int _indexOf(int value) => (value - widget.min) ~/ widget.step;

  int _valueAt(int index) => widget.min + index * widget.step;

  @override
  void didUpdateWidget(RulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int index = _indexOf(widget.value);
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
    final int value = _valueAt(index);
    if (value == widget.value) return;
    HapticFeedback.selectionClick();
    widget.onChanged(value);
  }

  void _jump(int value) =>
      _controller.jumpToItem(_indexOf(value.clamp(widget.min, widget.max)));

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int value = widget.value;
    final int step = widget.step;
    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticLabel,
      value: widget.valueLabel(value),
      increasedValue: value < widget.max
          ? widget.valueLabel(value + step)
          : null,
      decreasedValue: value > widget.min
          ? widget.valueLabel(value - step)
          : null,
      onIncrease: value < widget.max ? () => _jump(value + step) : null,
      onDecrease: value > widget.min ? () => _jump(value - step) : null,
      child: ExcludeSemantics(
        child: SizedBox(
          height: _height,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // A wheel turned on its side: its first number on the start
              // side, the next ones toward the end.
              RotatedBox(
                quarterTurns: rtl ? 1 : 3,
                child: ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: _step,
                  // A wheel this large is flat, as a ruler is.
                  diameterRatio: 1000,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: _select,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _indexOf(widget.max) + 1,
                    builder: (BuildContext context, int index) {
                      final int number = _valueAt(index);
                      final bool major =
                          widget.isMajor?.call(number) ??
                          (number == 1 || number % 5 == 0);
                      return RotatedBox(
                        quarterTurns: rtl ? 3 : 1,
                        child: _Tick(
                          major: major,
                          label: major
                              ? (widget.tickLabel?.call(number) ?? '$number')
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // The fixed mark, over the number chosen.
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 3,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppSemanticColors.pickerMark,
                      borderRadius: BorderRadius.circular(AppRadius.capsule),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One mark: a long one with its words under it, or a short one between.
class _Tick extends StatelessWidget {
  const _Tick({required this.major, this.label});

  final bool major;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: major ? 2 : 1,
          height: major ? 26 : 14,
          color: major
              ? AppSemanticColors.textPrimary
              : AppSemanticColors.borderControlBase,
        ),
        const Spacer(),
        // A number is wider than its mark: it overflows to both sides.
        SizedBox(
          height: 18,
          child: label != null
              ? OverflowBox(
                  maxWidth: 40,
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppSemanticColors.textSupporting),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
