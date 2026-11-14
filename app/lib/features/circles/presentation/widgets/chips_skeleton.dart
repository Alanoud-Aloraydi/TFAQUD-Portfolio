import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:flutter/material.dart';

class ChipsSkeleton extends StatelessWidget {
  const ChipsSkeleton({super.key, required this.widths});

  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final double width in widths)
          SkeletonBox(width: width, height: 36, radius: AppRadius.capsule),
      ],
    );
  }
}
