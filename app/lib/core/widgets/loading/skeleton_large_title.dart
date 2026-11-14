import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:flutter/material.dart';

/// The large title of a tab, and the line under it when [subtitle].
class SkeletonLargeTitle extends StatelessWidget {
  const SkeletonLargeTitle({
    super.key,
    this.width = 112,
    this.subtitle = false,
  });

  final double width;
  final bool subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SkeletonBox(width: width, height: 36, radius: AppRadius.s),
          if (subtitle) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: 104, height: 12),
          ],
        ],
      ),
    );
  }
}
