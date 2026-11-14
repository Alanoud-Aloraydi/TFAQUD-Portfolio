import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_large_title.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/medications/presentation/widgets/plan_card_skeleton.dart';
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
