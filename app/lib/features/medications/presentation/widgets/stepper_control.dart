import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The iOS stepper: a white outlined capsule with − and + divided by a thin
/// line, at the end of a row. Each half is 44 by
/// 44, so it is easy to tap. Null [onDecrement] or [onIncrement] turns that
/// half off, for example − at the smallest dose.
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
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: StadiumBorder(
          side: BorderSide(color: AppSemanticColors.borderControlBase),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Half(
            icon: AppIcons.minus,
            label: decrementLabel,
            onPressed: onDecrement,
          ),
          const SizedBox(
            height: AppSpacing.lg,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppSemanticColors.borderControlBase,
            ),
          ),
          _Half(
            icon: AppIcons.plus,
            label: incrementLabel,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.iconSmall),
      color: AppSemanticColors.textPrimary,
      disabledColor: AppSemanticColors.borderControlBase,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tight(const Size.square(AppSizes.touch)),
      style: IconButton.styleFrom(shape: const StadiumBorder()),
    );
  }
}
