import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_circle.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_surface.dart';
import 'package:flutter/material.dart';

class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonCircle(size: 40),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonLine(widthFactor: 0.5, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.9, height: 12),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonLine(widthFactor: 0.65, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 64, height: 24, radius: AppRadius.s),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppRadius.capsule,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppRadius.capsule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
