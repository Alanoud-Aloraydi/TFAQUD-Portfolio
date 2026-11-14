import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:flutter/material.dart';

/// A line of placeholder text, [widthFactor] of the row's width, from the
/// start (right in Arabic).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 1, this.height = 14});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: SkeletonBox(height: height),
      ),
    );
  }
}
