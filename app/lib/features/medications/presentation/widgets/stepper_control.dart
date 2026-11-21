import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/medications/presentation/widgets/stepper_half_button.dart';
import 'package:flutter/material.dart';

/// The dose stepper: + in a round lavender button, then [middle] (the
/// number and its unit), then − in a light one, at the end of a row. Null
/// [onDecrement] or [onIncrement] turns that button off, for example − at
/// the smallest dose.
class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.onDecrement,
    required this.onIncrement,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.middle,
  });

  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// What VoiceOver reads for each button, for example «إنقاص الجرعة».
  final String decrementLabel;
  final String incrementLabel;
  final Widget middle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      StepperHalfButton(
        icon: ActionIcons.plus,
        label: incrementLabel,
        onPressed: onIncrement,
        strong: true,
      ),
      middle,
      StepperHalfButton(
        icon: ActionIcons.minus,
        label: decrementLabel,
        onPressed: onDecrement,
      ),
    ],
  );
}
