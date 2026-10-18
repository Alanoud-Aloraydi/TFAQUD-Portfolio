import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/dev/component_gallery.dart';
import 'package:app/features/placeholder/placeholder_screen.dart';
import 'package:app/features/shell/app_shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routers.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.today,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        builder: (context, state) {
          return const Scaffold(body: LoadingWidget());
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          _branch(Routes.today, 'tab.today'),
          _branch(Routes.plan, 'tab.plan'),
          _branch(Routes.record, 'tab.record'),
          _branch(Routes.circle, 'tab.circle'),
        ],
      ),
      _standalone(Routes.account, 'topbar.account'),
      _standalone(Routes.notifications, 'topbar.notifications'),
      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          builder: (context, state) => const ComponentGallery(),
        ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(context.tr('error.not_found')))),
  );

  static StatefulShellBranch _branch(String path, String titleKey) {
    return StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: path,
          builder: (context, state) => PlaceholderScreen(titleKey: titleKey),
        ),
      ],
    );
  }

  static GoRoute _standalone(String path, String titleKey) {
    return GoRoute(
      path: path,
      builder: (context, state) =>
          PlaceholderScreen(titleKey: titleKey, standalone: true),
    );
  }
}
