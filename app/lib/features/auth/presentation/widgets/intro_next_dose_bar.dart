import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// The time left until the dose: the bar fills from the start side.
class IntroNextDoseBar extends StatelessWidget {
  const IntroNextDoseBar({super.key});

  static const double _bar = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _bar,
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: const FractionallySizedBox(
        widthFactor: 0.72,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppSemanticColors.actionPrimary,
            shape: StadiumBorder(),
          ),
        ),
      ),
    );
  }
}
