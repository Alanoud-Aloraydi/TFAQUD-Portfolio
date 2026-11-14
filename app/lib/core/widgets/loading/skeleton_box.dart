import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';

/// A grey placeholder shape. [width] null fills the row.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppSemanticColors.borderSubtle,
          shape: AppRadius.shape(radius),
        ),
      ),
    );
  }
}
