import 'dart:async';

import 'package:app/core/widgets/layout/refresh_header.dart';
import 'package:app/core/widgets/layout/refresh_pull.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:flutter/material.dart';

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
