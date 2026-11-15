import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:flutter/material.dart';

class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({super.key, required this.valueWidth, this.lines = 1});

  final double valueWidth;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SkeletonLine(widthFactor: 0.3, height: 12),
          for (int i = 0; i < lines; i++) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(widthFactor: valueWidth, height: 16),
          ],
        ],
      ),
    );
  }
}
