import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// Shimmer (design system Skeleton): a soft light band that sweeps over
/// the grey placeholder shapes of [child], from right to left in Arabic, every
/// 1.4 seconds. With Reduce Motion on, the shapes stay still.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        // The band travels from one side to the other, past both edges.
        final double travel = -1.5 + 3 * _controller.value;
        final double x = rtl ? -travel : travel;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) => LinearGradient(
            begin: Alignment(x - 0.6, -0.2),
            end: Alignment(x + 0.6, 0.2),
            colors: const <Color>[
              AppEffects.shimmerClear,
              AppEffects.shimmerHighlight,
              AppEffects.shimmerClear,
            ],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}
