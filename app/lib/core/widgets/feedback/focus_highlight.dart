import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/widgets.dart';

/// [child] under the tint [FocusMark] lays on it, as Telegram marks the
/// message a link opens: the brand lavender over the whole card, there at
/// once and fading away when [shown] turns false. It follows the card's
/// shape ([radius]), [inset] in from its edge, and takes no taps.
class FocusHighlight extends StatelessWidget {
  const FocusHighlight({
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
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: inset,
              child: AnimatedContainer(
                // Quick in, slow out: the tint is there as the card
                // arrives, then melts away.
                duration: still
                    ? Duration.zero
                    : (shown
                          ? AppMotion.fieldFeedback
                          : AppMotion.tapHighlightFade),
                curve: AppMotion.easeOut,
                decoration: ShapeDecoration(
                  color: AppSemanticColors.actionPrimary.withValues(
                    alpha: shown ? 0.55 : 0,
                  ),
                  shape: AppRadius.shape(radius),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
