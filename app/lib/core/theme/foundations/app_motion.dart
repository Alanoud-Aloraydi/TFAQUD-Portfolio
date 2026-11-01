import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Existing interface timing and curves, independent of business deadlines.
abstract class AppMotion {
  AppMotion._();

  static const Duration fieldFeedback = Duration(milliseconds: 120);
  static const Duration formScroll = Duration(milliseconds: 200);
  static const Duration segmentSlide = Duration(milliseconds: 260);
  static const Duration contentEnter = Duration(milliseconds: 280);
  static const Duration contentExit = Duration(milliseconds: 160);
  static const Duration alert = Duration(milliseconds: 320);
  static const Duration menuEnter = Duration(milliseconds: 420);
  static const Duration menuExit = Duration(milliseconds: 260);
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const int branchEnterMilliseconds = 260;
  static const int branchExitMilliseconds = 140;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInCubic = Curves.easeInCubic;
  static const double alertClosingScale = 0.96;
  static const double alertOpeningScale = 1.08;
  static const Curve alertSpring = Cubic(0.2, 0.9, 0.3, 1.04);
  static const Curve menuSpring = _GlassSpring();
  static const Curve branchEnter = Interval(0.3, 1, curve: Curves.easeOut);
}

/// Existing spring response shared by the custom glass menu.
class _GlassSpring extends Curve {
  const _GlassSpring();

  static final SpringSimulation _spring = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.72),
    0,
    1,
    0,
  );

  static const double _seconds = 0.42;

  @override
  double transformInternal(double t) => _spring.x(t * _seconds);
}
