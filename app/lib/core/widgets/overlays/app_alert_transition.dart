import 'dart:ui' show lerpDouble;

import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// How the alert comes and goes: it fades, and unless Reduce Motion is on it
/// also scales, from a little larger than its size with a small overshoot
/// when opening, and with a slight shrink while it fades when closing.
Widget appAlertTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final bool still = MediaQuery.disableAnimationsOf(context);
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final bool closing = animation.status == AnimationStatus.reverse;
      final double opacity = AppMotion.easeOut.transform(animation.value);
      if (still) return Opacity(opacity: opacity, child: child);
      // Opening: from 108% down to its size with a small overshoot.
      // Closing: a slight shrink while it fades.
      final double scale = closing
          ? lerpDouble(AppMotion.alertClosingScale, 1, animation.value)!
          : lerpDouble(
              AppMotion.alertOpeningScale,
              1,
              AppMotion.alertSpring.transform(animation.value),
            )!;
      return Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: child),
      );
    },
    child: child,
  );
}
