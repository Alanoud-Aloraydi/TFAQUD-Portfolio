import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A main page that reads its data again when pulled down from its top: a
/// header opens over the page with the loader growing as it is pulled,
/// «أفلت للتحديث» once far enough; let go, the page stays open over it
/// while everything is read, says «تم التحديث», then closes and the page
/// settles in. A short page can be pulled too. Without a [RefreshScope]
/// above it, the page is left as it is.
class PullToRefresh extends StatefulWidget {
  const PullToRefresh({super.key, required this.child});

  final Widget child;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with TickerProviderStateMixin {
  late final RefreshPull _pull = RefreshPull(this);

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  void _letGo() {
    final Future<void> Function()? refresh = RefreshScope.maybeOf(context);
    if (refresh == null) return;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    unawaited(_pull.run(refresh, calm: calm));
  }

  @override
  Widget build(BuildContext context) {
    if (RefreshScope.maybeOf(context) == null) return widget.child;
    final double top = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_pull, _pull.hold]),
      builder: (BuildContext context, Widget? page) => Stack(
        children: <Widget>[
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: RefreshHeader(
              stage: _pull.stage,
              height: _pull.pulled + _pull.push,
              reach: RefreshPull.reach,
            ),
          ),
          Transform.translate(
            offset: Offset(0, _pull.push),
            child: FadeTransition(opacity: _pull.settle, child: page),
          ),
        ],
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification note) {
          _pull.follow(note, _letGo);
          return false;
        },
        child: ScrollConfiguration(
          // The page follows the finger past its top, on every phone.
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// What shows in the gap a pulled page opens at its top: the loader,
/// growing and turning with the pull until [reach] lets go, and under it
/// what the [stage] says. [height] is how far the page is open over it;
/// both sit at the gap's bottom, by the page, so the gap opens down to
/// them and the whole logo shows, clear of the bar above.
class RefreshHeader extends StatelessWidget {
  const RefreshHeader({
    super.key,
    required this.stage,
    required this.height,
    required this.reach,
  });

  final RefreshStage stage;
  final double height;
  final double reach;

  @override
  Widget build(BuildContext context) {
    final String? words = stage.wordsKey;
    if (words == null || height <= 0) return const SizedBox.shrink();
    final double grown = (height / reach).clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: grown,
            child: Semantics(
              liveRegion: stage.isHeld,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TfaqudLoader(
                    size: 20 + 20 * grown,
                    animating: stage == RefreshStage.loading,
                    turn: grown / 2,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr(words),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: context.tokens.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A page's pull-down refresh, apart from how it is drawn: how far it is
/// [pulled], its [stage], and the [hold] and [settle] it moves by.
class RefreshPull extends ChangeNotifier {
  RefreshPull(TickerProvider vsync)
    : hold = AnimationController(vsync: vsync, duration: _move),
      settle = AnimationController(vsync: vsync, duration: _move, value: 1);

  static const Duration _move = AppMotion.contentEnter;

  /// The pull that lets go (the loader is full size there), and how far the
  /// page stays open while it reads: room for the whole logo and its words.
  static const double reach = 88;
  static const double held = 88;

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
