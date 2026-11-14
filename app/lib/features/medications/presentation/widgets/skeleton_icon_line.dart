import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:flutter/material.dart';

class SkeletonIconLine extends StatelessWidget {
  const SkeletonIconLine({super.key, required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SkeletonBox(width: 16, height: 16, radius: AppRadius.xs),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: SkeletonLine(widthFactor: widthFactor, height: 12)),
      ],
    );
  }
}
