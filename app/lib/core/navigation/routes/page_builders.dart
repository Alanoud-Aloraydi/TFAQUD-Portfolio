part of '../app_router.dart';

/// The redirect of a page whose subject travels only as the navigation's
/// `extra`, of type [T]. Without it (a cold start, a restored or typed
/// address, a deep link) the page cannot be built, so the phone goes to
/// [fallback], the page that is the way in.
GoRouterRedirect requireExtra<T>(String fallback) =>
    (BuildContext context, GoRouterState state) =>
        state.extra is T ? null : fallback;

// Detail pages change without a horizontal push animation.
GoRouterPageBuilder _iosPage(GoRouterWidgetBuilder builder) =>
    (BuildContext context, GoRouterState state) => NoTransitionPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: builder(context, state),
    );

// The notifications (the bell) and the account open as an iOS full-screen
// modal: the page rises from the bottom and goes back down when closed, and
// the page under it stays still. A modal has no back arrow and no edge
// swipe; its top has the close button (✕) instead, on the leading side, as
// Apple's guidelines ask for a modal view (Human Interface Guidelines,
// Modality and Sheets).
GoRouterPageBuilder _iosModalPage(GoRouterWidgetBuilder builder) =>
    (BuildContext context, GoRouterState state) => CupertinoPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      fullscreenDialog: true,
      child: builder(context, state),
    );

ShellRoutePageBuilder _iosShellPage(ShellRouteBuilder builder) =>
    (BuildContext context, GoRouterState state, Widget child) =>
        CupertinoPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: builder(context, state, child),
        );

StatefulShellRoutePageBuilder _iosShellRootPage(
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
