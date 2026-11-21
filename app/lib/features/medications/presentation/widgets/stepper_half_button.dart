import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// One round button of the dose stepper: a 34 point circle drawn inside a
/// 44 point tap. [strong] is + in the app's lavender; − is the light one.
/// Null [onPressed] greys it out, at its end of the range.
class StepperHalfButton extends StatelessWidget {
  const StepperHalfButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.strong = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool strong;

  static const double _circle = 34;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints.tight(const Size.square(AppSizes.touch)),
    icon: Container(
      width: _circle,
      height: _circle,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onPressed == null
            ? AppSemanticColors.selectedSurface
            : strong
            ? AppSemanticColors.actionPrimary
            : AppSemanticColors.selectedSurface,
      ),
      child: Icon(
        icon,
        size: AppSizes.iconSmall,
        color: onPressed == null
            ? AppSemanticColors.borderControlBase
            : strong
            ? AppSemanticColors.onActionPrimary
            : AppSemanticColors.actionStrong,
      ),
    ),
  );
}
