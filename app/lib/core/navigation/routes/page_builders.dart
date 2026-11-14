part of '../app_router.dart';

/// The redirect of a page whose subject travels only as the navigation's
/// `extra`, of type [T]. Without it (a cold start, a restored or typed
/// address, a deep link) the page cannot be built, so the phone goes to
/// [fallback], the page that is the way in.
GoRouterRedirect requireExtra<T>(String fallback) =>
    (BuildContext context, GoRouterState state) =>
        state.extra is T ? null : fallback;

// A page with «رجوع» is an iOS page (CupertinoPage): it slides in from the
// side opposite «رجوع» and goes back out the same way, and a swipe from the
// edge of the screen where «رجوع» sits takes it back, the previous page
// following the finger. In Arabic that edge is the right: a new page comes
// in from the left, as iOS does in Arabic (Human Interface Guidelines,
// Right to left; Navigation, Edge swipe). A page that is the first of its
// navigator, or that keeps the user from leaving (PopScope), has no swipe.
GoRouterPageBuilder _iosPage(GoRouterWidgetBuilder builder) =>
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
