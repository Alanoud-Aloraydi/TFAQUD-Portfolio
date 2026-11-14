import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

class EmergencySegment extends StatelessWidget {
  const EmergencySegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppSemanticColors.surfaceContent
            : AppSemanticColors.transparent,
        shape: StadiumBorder(
          side: selected
              ? const BorderSide(color: AppSemanticColors.borderPlan)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _height,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppSemanticColors.textPrimary
                      : AppSemanticColors.textSupporting,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
