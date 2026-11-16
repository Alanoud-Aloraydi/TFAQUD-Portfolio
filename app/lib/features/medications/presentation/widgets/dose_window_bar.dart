import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// How much of a dose's window is left, as a capsule that empties from the
/// start side. [remaining] is between 0 and 1.
class DoseWindowBar extends StatelessWidget {
  const DoseWindowBar({super.key, required this.remaining});

  final double remaining;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.capsule),
      child: SizedBox(
        height: AppSpacing.tight,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppSemanticColors.doseTrack),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: remaining,
                child: const ColoredBox(
                  color: AppSemanticColors.textSupporting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
