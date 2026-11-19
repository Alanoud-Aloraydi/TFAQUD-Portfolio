import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/presentation/widgets/stepper_half_button.dart';
import 'package:flutter/material.dart';

/// The dose stepper: a lavender capsule with − and + divided by a thin
/// line, at the end of a row. Each half is 44 by 44, so it is easy to tap.
/// Null [onDecrement] or [onIncrement] turns that half off, for example −
/// at the smallest dose.
class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.onDecrement,
    required this.onIncrement,
    required this.decrementLabel,
    required this.incrementLabel,
  });

  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// What VoiceOver reads for each half, for example «إنقاص الجرعة».
  final String decrementLabel;
  final String incrementLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppSemanticColors.selectedSurface,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StepperHalfButton(
            icon: ActionIcons.minus,
            label: decrementLabel,
            onPressed: onDecrement,
          ),
          const SizedBox(
            height: AppSpacing.lg,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppSemanticColors.selectedSurfaceStrong,
            ),
          ),
          StepperHalfButton(
            icon: ActionIcons.plus,
            label: incrementLabel,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
