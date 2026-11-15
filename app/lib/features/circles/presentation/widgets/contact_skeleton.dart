import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_circle.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_surface.dart';
import 'package:flutter/material.dart';

class ContactSkeleton extends StatelessWidget {
  const ContactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Row(
        children: <Widget>[
          SkeletonCircle(size: 40),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonLine(widthFactor: 0.45, height: 16),
                SizedBox(height: AppSpacing.sm),
                SkeletonLine(widthFactor: 0.35, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 20, height: 20, radius: AppRadius.xs),
        ],
      ),
    );
  }
}
