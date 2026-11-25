import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:flutter/material.dart';

/// «الخطة» while it loads ([filter] false) and «السجل» ([filter] true): the
/// large title, the segmented control on «السجل» or the section title on
/// «الخطة», then medicine cards.
class PlansSkeleton extends StatelessWidget {
  const PlansSkeleton({super.key, this.filter = false});

  final bool filter;

  @override
  Widget build(BuildContext context) {
    return SkeletonPage(
      children: <Widget>[
        const SkeletonLargeTitle(width: 88),
        if (filter) ...<Widget>[
          const SkeletonBox(height: AppSizes.touch, radius: AppRadius.capsule),
          const SizedBox(height: AppSpacing.xl),
        ] else ...<Widget>[
          const SkeletonLine(widthFactor: 0.38, height: 24),
          const SizedBox(height: AppSpacing.md),
        ],
        for (int i = 0; i < 3; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          const PlanCardSkeleton(),
        ],
      ],
    );
  }
}

/// A medicine card: the icon, the name, the status pill and the chevron,
/// the strength line, and the two lines with an icon each.
class PlanCardSkeleton extends StatelessWidget {
  const PlanCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SkeletonBox(width: 24, height: 24, radius: AppRadius.xs),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonLine(widthFactor: 0.55, height: 20)),
              SkeletonBox(width: 56, height: 24, radius: AppRadius.s),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 12, height: 20),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          SkeletonLine(widthFactor: 0.35),
          SizedBox(height: AppSpacing.md),
          SkeletonIconLine(widthFactor: 0.45),
          SizedBox(height: AppSpacing.xs),
          SkeletonIconLine(widthFactor: 0.6),
        ],
      ),
    );
  }
}

class SkeletonIconLine extends StatelessWidget {
  const SkeletonIconLine({super.key, required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SkeletonBox(width: 16, height: 16, radius: AppRadius.xs),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: SkeletonLine(widthFactor: widthFactor, height: 12)),
      ],
    );
  }
}
