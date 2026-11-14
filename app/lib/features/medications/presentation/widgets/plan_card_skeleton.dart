import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_surface.dart';
import 'package:app/features/medications/presentation/widgets/skeleton_icon_line.dart';
import 'package:flutter/material.dart';

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
