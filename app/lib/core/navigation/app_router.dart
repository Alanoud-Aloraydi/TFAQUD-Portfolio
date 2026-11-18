import 'package:app/core/navigation/routes/app_routes.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'routers.dart';

export 'routes/require_extra.dart';

/// Defines page routes and navigation behavior.
class AppRouter {
  // How the app decides what to show:
  //
  // 1. The first page is the splash page. It asks the server whether this
  //    phone is signed in, then goes to the home page or the sign-in page.
  // 2. Every other page needs the tokens of a signed-in phone. Without them
  //    the router sends the user to the sign-in page, however the page was
  //    asked for: a tap, an address typed in the browser, or a reload. This
  //    only decides what the app shows. The data is protected by the server,
  //    which refuses every request that has no valid token.
  // 3. On the web a reload keeps the address, so the first navigation is
  //    also sent to the splash page, which checks the session with the
  //    server. A phone always starts at the splash page.
  static bool _startChecked = false;

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) async {
      final String location = state.matchedLocation;
      if (kIsWeb && !_startChecked) {
        _startChecked = true;
        if (location != Routes.splash) return Routes.splash;
      }
      String? token;
      try {
        token = await GetIt.I<TokenStorage>().readAccessToken();
      } catch (_) {
        // The tokens cannot be read (the secure storage failed): the phone
        // counts as signed out.
      }
      return signInRedirect(
        location,
        hasTokens: token != null && token.isNotEmpty,
      );
    },
    routes: appRoutes(),
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(context.tr('error.not_found')))),
  );

  /// The page a phone is sent to instead of [location], or null when it may
  /// open [location]. The splash page and the sign-in pages are open to
  /// everyone, and in a debug build the component gallery too (it exists
  /// only there). Every other page needs the tokens ([hasTokens]); without
  /// them the phone is sent to the sign-in page.
  @visibleForTesting
  static String? signInRedirect(String location, {required bool hasTokens}) {
    if (hasTokens) return null;
    final bool open =
        location == Routes.splash ||
        (kDebugMode && location == Routes.gallery) ||
        location == Routes.auth ||
        location.startsWith('${Routes.auth}/');
    return open ? null : Routes.auth;
  }
}
