import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:flutter/material.dart';

/// The capsule that slides under the chosen segment of a segmented control:
/// the [index]th of segments [width] wide each.
class GlassSegmentThumb extends StatelessWidget {
  const GlassSegmentThumb({
    super.key,
    required this.index,
    required this.width,
  });

  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return AnimatedPositionedDirectional(
      duration: still ? Duration.zero : AppMotion.segmentSlide,
      curve: AppMotion.easeOutCubic,
      start: index * width,
      width: width,
      top: 0,
      bottom: 0,
      child: const DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(),
          color: AppGlass.normalBottom,
          shadows: AppEffects.segmentShadow,
        ),
      ),
    );
  }
}
