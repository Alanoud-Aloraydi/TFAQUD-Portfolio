import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// The rise of a page's cards: it plays once each time the page shows, and
/// not at all with Reduce Motion.
mixin IntroEnterAnimation<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController enter = AnimationController(
    vsync: this,
    duration: AppMotion.introEnter,
  );

  bool _reduceMotion = false;
  bool _started = false;

  /// Whether this is the page on show.
  bool get introActive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      enter.value = 1;
    } else if (!_started && introActive) {
      playEnter();
    }
    _started = true;
  }

  void playEnter() {
    if (_reduceMotion) {
      enter.value = 1;
    } else {
      enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    enter.dispose();
    super.dispose();
  }
}
