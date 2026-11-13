import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lets a page be swiped to the right, starting anywhere on it, to do what
/// its «رجوع» does, as a page's back swipe does on iOS. The page's
/// [BackLink] says what that is; a page with no «رجوع» does nothing (a
/// modal closes with its ✕ only, as Apple's guidelines ask). While the
/// finger moves the page follows it a little, so the swipe is seen;
/// with Reduce Motion it stays still.
///
/// A swipe that a part of the page needs itself (a horizontal list, a
/// ruler) stays that part's: the innermost one wins.
class SwipeBack extends StatefulWidget {
  const SwipeBack({super.key, required this.child});

  final Widget child;

  /// The swipe of the page around [context], for its «رجوع».
  static SwipeBackState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SwipeBackState>();

  @override
  State<SwipeBack> createState() => SwipeBackState();
}

/// The swipe of one page: what it does, given by the page's «رجوع».
class SwipeBackState extends State<SwipeBack> {
  Object? _owner;
  VoidCallback? _back;
  double _dx = 0;
  final ValueNotifier<double> _shift = ValueNotifier<double>(0);

  /// How far to the right, or how fast, a swipe goes back.
  static const double _distance = 72;
  static const double _speed = 700;

  /// How far the page follows the finger, at most.
  static const double _follow = 40;

  /// [owner]'s «رجوع» does [back] when the page is swiped.
  void register(Object owner, VoidCallback back) {
    _owner = owner;
    _back = back;
  }

  /// [owner] is gone: its «رجوع» no longer answers the swipe.
  void unregister(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    _back = null;
  }

  @override
  void dispose() {
    _shift.dispose();
    super.dispose();
  }

  void _start(DragStartDetails details) => _dx = 0;

  void _update(DragUpdateDetails details) {
    if (_back == null) return;
    _dx += details.delta.dx;
    final bool still = MediaQuery.disableAnimationsOf(context);
    _shift.value = still ? 0 : math.min(math.max(_dx, 0), _follow * 2) / 2;
  }

  void _end(DragEndDetails details) {
    final VoidCallback? back = _back;
    final double speed = details.primaryVelocity ?? 0;
    _shift.value = 0;
    if (back == null || speed < 0) return;
    if (_dx >= _distance || speed >= _speed) back();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragStart: _start,
    onHorizontalDragUpdate: _update,
    onHorizontalDragEnd: _end,
    onHorizontalDragCancel: () => _shift.value = 0,
    child: ValueListenableBuilder<double>(
      valueListenable: _shift,
      builder: (BuildContext context, double shift, Widget? child) =>
          Transform.translate(offset: Offset(shift, 0), child: child),
      child: widget.child,
    ),
  );
}
