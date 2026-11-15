import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:flutter/material.dart';

class SkeletonLabelValue extends StatelessWidget {
  const SkeletonLabelValue({super.key, required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SkeletonLine(widthFactor: 0.25, height: 12),
        const SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: valueWidth, height: 16),
      ],
    );
  }
}
