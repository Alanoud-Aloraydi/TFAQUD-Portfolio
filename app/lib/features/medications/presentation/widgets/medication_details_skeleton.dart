import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:flutter/material.dart';

/// A medicine's page while it loads: the name and strength, the details
/// card, and the dose times.
class MedicationDetailsSkeleton extends StatelessWidget {
  const MedicationDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonLine(widthFactor: 0.55, height: 24),
        SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: 0.3),
        SizedBox(height: AppSpacing.lg),
        SkeletonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonLabelValue(valueWidth: 0.5),
              SizedBox(height: AppSpacing.md),
              SkeletonLabelValue(valueWidth: 0.4),
              SizedBox(height: AppSpacing.md),
              SkeletonLabelValue(valueWidth: 0.6),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.3, height: 20),
        SizedBox(height: AppSpacing.md),
        SkeletonLabelValue(valueWidth: 0.45),
        SizedBox(height: AppSpacing.md),
        SkeletonLabelValue(valueWidth: 0.45),
      ],
    );
  }
}

class SkeletonLabelValue extends StatelessWidget {
  const SkeletonLabelValue({super.key, required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SkeletonLine(widthFactor: 0.25, height: 12),
        const SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: valueWidth, height: 16),
      ],
    );
  }
}
