import 'package:app/core/widgets/layout/pull_to_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// One home tab at [path], drawn by [builder] (an empty page without one).
StatefulShellBranch homeTabBranch(
  String path, {
  GoRouterWidgetBuilder? builder,
}) {
  final GoRouterWidgetBuilder page =
      builder ?? (context, state) => const SizedBox.expand();
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        // A tab page is the first page of its own navigator, see-through
        // to the shell's canvas: an iOS page (CupertinoPage) draws a 9%
        // shadow under itself that darkened the whole tab. A tab never
        // slides in (tabs fade), so it is a plain page; pulled down from
        // its top, it reads everything again.
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          name: state.name ?? state.path,
          restorationId: state.pageKey.value,
          child: PullToRefresh(child: page(context, state)),
        ),
      ),
    ],
  );
}
