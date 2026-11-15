import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_block.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
import 'package:flutter/material.dart';

/// The dose history inside a medicine's page while it loads: its title and
/// dose rows. It sits inside the page's scrolling list, so it does not
/// scroll itself.
class DoseHistorySkeleton extends StatelessWidget {
  const DoseHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBlock(
      children: <Widget>[
        SkeletonLine(widthFactor: 0.35, height: 24),
        SizedBox(height: AppSpacing.sm),
        DoseRowSkeleton(),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
      ],
    );
  }
}
