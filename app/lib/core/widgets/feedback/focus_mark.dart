import 'dart:async';

import 'package:app/core/services/tap_focus.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/feedback/focus_outline.dart';
import 'package:flutter/material.dart';

/// Brings [child] into view and outlines it for a moment when the
/// notification just tapped is about it ([TapFocus]), so the person sees
/// at once which dose, reading, visit or request it meant ([FocusOutline];
/// [inset] leaves out a card's own margin).
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

  /// The corner radius of [child], which the outline follows.
  final double radius;
  final EdgeInsetsGeometry inset;
  final Widget child;

  @override
  State<FocusMark> createState() => _FocusMarkState();
}

class _FocusMarkState extends State<FocusMark> {
  Timer? _timer;
  bool _outlined = false;

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
    // After the prayer period it is in has opened.
    _timer?.cancel();
    _timer = Timer(AppMotion.disclosure, () => unawaited(_bring()));
  }

  Future<void> _bring() async {
    if (!mounted) return;
    final bool still = MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      context,
      alignment: 0.3,
      duration: still ? Duration.zero : AppMotion.formScroll,
      curve: AppMotion.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _outlined = true);
    _timer = Timer(TapFocus.outlineFor, () {
      if (mounted) setState(() => _outlined = false);
    });
  }

  @override
  Widget build(BuildContext context) => FocusOutline(
    shown: _outlined,
    radius: widget.radius,
    inset: widget.inset,
    child: widget.child,
  );
}
