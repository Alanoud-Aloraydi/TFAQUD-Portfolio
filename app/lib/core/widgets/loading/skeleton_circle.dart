import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:flutter/material.dart';

/// A round placeholder, such as an avatar.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, radius: size / 2);
  }
}
