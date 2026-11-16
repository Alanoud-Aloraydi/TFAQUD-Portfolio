import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

class StepperHalfButton extends StatelessWidget {
  const StepperHalfButton({
    super.key,
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
