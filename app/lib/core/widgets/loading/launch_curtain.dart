import 'dart:async';

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/loading/pulsing_logo.dart';
import 'package:flutter/material.dart';

/// The launch screen kept over the app as it starts: white, and the logo
/// breathing where iOS's own launch screen put it (160 points, centred).
/// It stays [AppMotion.launchHold] at least, and until the first page knows
/// where to go ([ready]); then it fades away in place, so the app appears
/// under it instead of sliding in from the side.
class LaunchCurtain extends StatefulWidget {
  const LaunchCurtain({super.key, required this.child});

  final Widget child;

  /// Set by the first page once it is going somewhere, or has something to
  /// show (the retry when the session could not be checked).
  static final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  @override
  State<LaunchCurtain> createState() => _LaunchCurtainState();
}

class _LaunchCurtainState extends State<LaunchCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.launchFade,
    value: 1,
  );
  late final Timer _hold;
  bool _held = true;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _hold = Timer(AppMotion.launchHold, () {
      _held = false;
      _onReady();
    });
    LaunchCurtain.ready.addListener(_onReady);
  }

  void _onReady() => unawaited(_lift());

  Future<void> _lift() async {
    if (_held || !LaunchCurtain.ready.value || _gone || _fade.isAnimating) {
      return;
    }
    await _fade.reverse();
    if (mounted) setState(() => _gone = true);
  }

  @override
  void dispose() {
    _hold.cancel();
    LaunchCurtain.ready.removeListener(_onReady);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      widget.child,
      if (!_gone)
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: const ColoredBox(
              color: AppSemanticColors.surfaceContent,
              child: Center(child: PulsingLogo(size: AppSizes.loadingPage)),
            ),
          ),
        ),
    ],
  );
}
