import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';

/// [child] with the outline [FocusMark] gives it: the focus color, outside
/// the child's edge and [inset] in from it, fading in and out as [shown]
/// changes. The outline covers nothing of the child and takes no taps.
class FocusOutline extends StatelessWidget {
  const FocusOutline({
    super.key,
    required this.shown,
    required this.radius,
    required this.inset,
    required this.child,
  });

  final bool shown;
  final double radius;
  final EdgeInsetsGeometry inset;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    clipBehavior: Clip.none,
    children: <Widget>[
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: Padding(
            padding: inset,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.disclosure,
              decoration: ShapeDecoration(
                shape: AppRadius.shape(
                  radius,
                  side: BorderSide(
                    color: shown ? context.tokens.focus : Colors.transparent,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
