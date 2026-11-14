import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// A card that fades in and rises 18 points into place, after the cards
/// before it ([order] 0 comes first).
class IntroRise extends StatelessWidget {
  const IntroRise({
    super.key,
    required this.enter,
    required this.order,
    required this.child,
  });

  final Animation<double> enter;
  final int order;
  final Widget child;

  static const double _distance = 18;

  @override
  Widget build(BuildContext context) {
    final Interval curve = Interval(
      order * 0.15,
      order * 0.15 + 0.55,
      curve: AppMotion.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: enter,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = curve.transform(enter.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _distance),
            child: child,
          ),
        );
      },
    );
  }
}
