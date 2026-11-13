import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// [child] while [open]: opening, it slides down from under the line above
/// it and fades in; closing, it slides back up and fades out, as a
/// disclosure opens on iOS. With Reduce Motion it shows and hides at once.
/// Closed, it is not built.
class ExpandReveal extends StatelessWidget {
  const ExpandReveal({super.key, required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: open ? 1 : 0),
      duration: still ? Duration.zero : AppMotion.contentEnter,
      curve: AppMotion.easeOutCubic,
      builder: (BuildContext context, double shown, Widget? child) {
        if (shown == 0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            // The bottom first: the content comes down from the line above.
            alignment: AlignmentDirectional.bottomStart,
            heightFactor: shown,
            child: Opacity(opacity: shown, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
