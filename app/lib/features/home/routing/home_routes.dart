import 'package:app/app/router/fading_branches.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/core/widgets/layout/pull_to_refresh.dart';
import 'package:app/features/circles/presentation/pages/circle_tab_screen.dart';
import 'package:app/features/home/presentation/pages/home_feature_screen.dart';
import 'package:app/features/home/presentation/pages/plan_page.dart';
import 'package:app/features/home/presentation/pages/record_page.dart';
import 'package:app/features/home/presentation/pages/today_page.dart';
import 'package:app/features/home/routing/home_shell_cubits.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The detailed mode's home: four tabs (اليوم، الخطة، السجل، الدائرة) under
/// one shell that provides the cubits every tab shares.
StatefulShellRoute homeShell() => StatefulShellRoute(
  // The tabs fade into each other instead of swapping at once.
  navigatorContainerBuilder: (context, navigationShell, children) =>
      FadingBranches(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
  pageBuilder: iosShellRootPage(
    (context, state, navigationShell) => homeShellCubits(
      child: HomeFeatureScreen(navigationShell: navigationShell),
    ),
  ),
  branches: <StatefulShellBranch>[
    homeTabBranch(Routes.today, builder: (context, state) => const TodayPage()),
    homeTabBranch(Routes.plan, builder: (context, state) => const PlanPage()),
    homeTabBranch(
      Routes.record,
      builder: (context, state) => const RecordPage(),
    ),
    // The circle tab shows the selected circle with the buttons of its
    // medical file and its emergency card.
    homeTabBranch(
      Routes.circle,
      builder: (context, state) => const CircleTabScreen(),
    ),
  ],
);

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
