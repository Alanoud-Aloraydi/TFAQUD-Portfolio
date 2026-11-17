import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/layout/refresh_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A page's pull-down refresh, apart from how it is drawn: how far it is
/// [pulled], its [stage], and the [hold] and [settle] it moves by.
class RefreshPull extends ChangeNotifier {
  RefreshPull(TickerProvider vsync)
    : hold = AnimationController(vsync: vsync, duration: _move),
      settle = AnimationController(vsync: vsync, duration: _move, value: 1);

  static const Duration _move = AppMotion.contentEnter;

  /// The pull that lets go (the loader is full size there), and how far
  /// the page then stays open over the header while it reads.
  static const double reach = 88;
  static const double held = 72;

  final AnimationController hold;
  final AnimationController settle;
  double pulled = 0;
  RefreshStage stage = RefreshStage.idle;
  bool _dragging = false;
  bool _gone = false;

  // How far the hold pushes the page past what its own bounce gives.
  double get push => math.max(0.0, held * hold.value - pulled);

  /// Follows the page's scroll; [letGo] once it is let go far enough.
  void follow(ScrollNotification note, VoidCallback letGo) {
    if (note.depth != 0 || note.metrics.axis != Axis.vertical) return;
    _dragging = switch (note) {
      ScrollStartNotification(:final dragDetails) => dragDetails != null,
      ScrollUpdateNotification(:final dragDetails) => dragDetails != null,
      ScrollEndNotification() => false,
      _ => _dragging,
    };
    final double was = pulled;
    pulled = math.max(0.0, note.metrics.minScrollExtent - note.metrics.pixels);
    if (!_dragging && stage == RefreshStage.armed) {
      letGo();
    } else if (!stage.isHeld && (_dragging || pulled == 0)) {
      _show(switch (pulled) {
        >= reach => RefreshStage.armed,
        > 0 => RefreshStage.pulling,
        _ => RefreshStage.idle,
      });
    }
    if (pulled != was) notifyListeners();
  }

  /// Held open until [refresh] is done, «تم التحديث» a moment, then closed
  /// and the page faded back in (at once when motion is [calm]).
  Future<void> run(
    Future<void> Function() refresh, {
    required bool calm,
  }) async {
    _show(RefreshStage.loading);
    hold.value = 1;
    try {
      await refresh();
    } finally {
      if (!_gone) _show(RefreshStage.done);
    }
    await Future<void>.delayed(AppMotion.refreshDone);
    if (_gone) return;
    if (!calm) unawaited(settle.forward(from: 0.4));
    await hold.animateTo(0, duration: calm ? Duration.zero : null);
    if (!_gone) _show(RefreshStage.idle);
  }

  void _show(RefreshStage next) {
    if (next == stage) return;
    if (next == RefreshStage.armed) unawaited(HapticFeedback.selectionClick());
    stage = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _gone = true;
    hold.dispose();
    settle.dispose();
    super.dispose();
  }
}
