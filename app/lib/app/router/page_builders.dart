import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

GoRouterPageBuilder iosPage(GoRouterWidgetBuilder builder) =>
    (BuildContext context, GoRouterState state) => CupertinoPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: builder(context, state),
    );

// The notifications (the bell), the account, and the forms that add or
// change a plan or an appointment open as an iOS full-screen modal: the
// page rises from the bottom and goes back down when closed, and the page
// under it stays still. A modal has no back arrow and no edge
// swipe; its top has the close button (✕) instead, on the leading side, as
// Apple's guidelines ask for a modal view (Human Interface Guidelines,
// Modality and Sheets).
GoRouterPageBuilder iosModalPage(GoRouterWidgetBuilder builder) =>
    (BuildContext context, GoRouterState state) => CupertinoPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      fullscreenDialog: true,
      child: builder(context, state),
    );

ShellRoutePageBuilder iosShellPage(ShellRouteBuilder builder) =>
    (BuildContext context, GoRouterState state, Widget child) =>
        CupertinoPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: builder(context, state, child),
        );

StatefulShellRoutePageBuilder iosShellRootPage(
  StatefulShellRouteBuilder builder,
) =>
    (
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    ) => CupertinoPage<void>(
      key: state.pageKey,
      restorationId: state.pageKey.value,
      child: builder(context, state, navigationShell),
    );
