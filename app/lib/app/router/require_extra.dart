import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The redirect of a page whose subject travels only as the navigation's
/// `extra`, of type [T]. Without it (a cold start, a restored or typed
/// address, a deep link) the page cannot be built, so the phone goes to
/// [fallback], the page that is the way in.
GoRouterRedirect requireExtra<T>(String fallback) =>
    (BuildContext context, GoRouterState state) =>
        state.extra is T ? null : fallback;
