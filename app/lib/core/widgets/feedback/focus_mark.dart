import 'dart:async';

import 'package:app/app/services/tap_focus.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Brings [child] to the middle of the screen and tints it for a second
/// when the notification just tapped is about it ([TapFocus]), as Telegram
/// marks the message a link opens, so the person sees at once which dose,
/// reading, visit or request it meant ([FocusHighlight]; [inset] leaves out
/// a card's own margin).
class FocusMark extends StatefulWidget {
  const FocusMark({
    super.key,
    required this.itemKey,
    required this.radius,
    required this.child,
    this.inset = EdgeInsets.zero,
  });

  /// The item's key, as [TapFocus] names it.
  final String itemKey;

  /// The corner radius of [child], which the tint follows.
  final double radius;
  final EdgeInsetsGeometry inset;
  final Widget child;

  @override
  State<FocusMark> createState() => _FocusMarkState();
}

class _FocusMarkState extends State<FocusMark> {
  Timer? _timer;
  bool _lit = false;

  @override
  void initState() {
    super.initState();
    TapFocus.instance.addListener(_check);
    _check();
  }

  @override
  void didUpdateWidget(FocusMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  @override
  void dispose() {
    TapFocus.instance.removeListener(_check);
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    if (!TapFocus.instance.claim(widget.itemKey)) return;
    // After the prayer period or the box it is in has opened.
    _timer?.cancel();
    _timer = Timer(AppMotion.contentEnter, () => unawaited(_bring()));
  }

  Future<void> _bring() async {
    if (!mounted) return;
    final bool still = MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      context,
      alignment: 0.4,
      duration: still ? Duration.zero : AppMotion.formScroll,
      curve: AppMotion.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _lit = true);
    _timer = Timer(AppMotion.tapHighlight, () {
      if (mounted) setState(() => _lit = false);
    });
  }

  @override
  Widget build(BuildContext context) => FocusHighlight(
    shown: _lit,
    radius: widget.radius,
    inset: widget.inset,
    child: widget.child,
  );
}

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
