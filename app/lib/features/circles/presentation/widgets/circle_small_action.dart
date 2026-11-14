import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A small white capsule with a line edge (32 points high); its tap area is
/// 48 points.
class CircleSmallAction extends StatelessWidget {
  const CircleSmallAction({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// False while another change of the members is on its way.
  final bool enabled;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, _height),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.padded,
        side: const BorderSide(color: AppSemanticColors.borderPlan),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
      child: Text(label),
    );
  }
}
