import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/home_shell_cubits.dart';
import 'package:app/core/navigation/routes/home_tab_branch.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/features/circles/presentation/pages/circle_tab_screen.dart';
import 'package:app/features/home/presentation/pages/home_feature_screen.dart';
import 'package:app/features/home/presentation/pages/plan_page.dart';
import 'package:app/features/home/presentation/pages/record_page.dart';
import 'package:app/features/home/presentation/pages/today_page.dart';
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
