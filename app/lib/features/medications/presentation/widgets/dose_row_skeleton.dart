import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:flutter/material.dart';

/// One dose row: the time column with its line, the medicine's name,
/// strength and dose, and (when [withButtons]) the record buttons.
class DoseRowSkeleton extends StatelessWidget {
  const DoseRowSkeleton({super.key, this.withButtons = false});

  final bool withButtons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: <Widget>[
                    SkeletonBox(width: 52, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 44, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonLine(widthFactor: 0.55, height: 20),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.3),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.4, height: 12),
                  ],
                ),
              ),
            ],
          ),
          if (withButtons) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(
              height: AppSizes.button,
              radius: AppRadius.capsule,
            ),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(
              height: AppSizes.touch,
              radius: AppRadius.capsule,
            ),
          ],
        ],
      ),
    );
  }
}
