import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_large_title.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
import 'package:flutter/material.dart';

// Each medicine page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for, so nothing jumps when the content
// comes.

/// «اليوم» while it loads: the large title and the date, «أدوية اليوم», then
/// dose rows as the real ones: the time on the start side, the medicine's
/// lines, and the record buttons, divided by lines.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonLargeTitle(width: 96, subtitle: true),
        SkeletonLine(widthFactor: 0.32, height: 24),
        SizedBox(height: AppSpacing.md),
        DoseRowSkeleton(withButtons: true),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
      ],
    );
  }
}
