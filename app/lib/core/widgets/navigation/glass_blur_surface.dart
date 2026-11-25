import 'dart:ui' show ImageFilter;

import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:flutter/material.dart';

/// The translucent path of the glass surface: a soft shadow, a background
/// blur, a fill lighter at the top, a hairline edge with a bright inner rim
/// concentric to it, and a specular highlight near the top start corner.
Widget glassBlurSurface({
  required BorderRadius borderRadius,
  required bool dense,
  required Widget child,
}) {
  // The inner rim sits inside the hairline edge: its radius is the outer
  // radius minus the edge width, so the two stay concentric.
  final BorderRadius inner =
      borderRadius -
      const BorderRadius.all(Radius.circular(AppGlass.edgeWidth));

  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: borderRadius,
      boxShadow: AppGlass.shadow,
    ),
    child: ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: DecoratedBox(
          // Accessible opaque surfaces return above; this is the glass path.
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dense
                  ? const <Color>[AppGlass.denseTop, AppGlass.denseBottom]
                  : const <Color>[AppGlass.normalTop, AppGlass.normalBottom],
            ),
            border: Border.all(
              color: AppEffects.subtleEdge,
              width: AppGlass.edgeWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppGlass.edgeWidth),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              // Bright inner rim, over the content like a lens edge.
              decoration: BoxDecoration(
                borderRadius: inner,
                border: Border.all(
                  color: AppGlass.innerRim,
                  width: AppGlass.rimWidth,
                ),
              ),
              // The specular highlight lies in the glass, under the
              // content: a dark card in a glass sheet (the + sheet's
              // «سجّل قراءة الآن») keeps its flat color, as in the handoff.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: inner,
                  gradient: const RadialGradient(
                    center: AlignmentDirectional(-0.55, -0.85),
                    radius: 0.9,
                    colors: <Color>[AppGlass.highlight, AppGlass.clear],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
