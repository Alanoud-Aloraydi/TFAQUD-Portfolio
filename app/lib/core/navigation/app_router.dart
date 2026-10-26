import 'package:app/core/services/token_storage.dart';
import 'package:app/dev/component_gallery.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/pages/account_prototype_screen.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:app/features/auth/presentation/pages/auth_feature_screen.dart';
import 'package:app/features/auth/presentation/pages/code_screen.dart';
import 'package:app/features/auth/presentation/pages/phone_screen.dart';
import 'package:app/features/auth/presentation/pages/splash_screen.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_state.dart';
import 'package:app/features/circles/presentation/pages/self_circle_allergies_screen.dart';
import 'package:app/features/circles/presentation/pages/self_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/self_circle_health_screen.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/pages/home_feature_screen.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/onboarding_feature_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:app/features/placeholder/placeholder_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'routers.dart';

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
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => BlocProvider(
          create: (context) => SplashCubit(GetIt.I<AuthUseCase>())..decide(),
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: Routes.home,
        redirect: (context, state) => Routes.today,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          create: (context) => HomeCubit(GetIt.I<HomeUseCase>())..load(),
          child: HomeFeatureScreen(navigationShell: navigationShell),
        ),
        branches: <StatefulShellBranch>[
          _branch(Routes.today),
          _branch(Routes.plan),
          _branch(Routes.record),
          _branch(Routes.circle),
        ],
      ),
      GoRoute(
        path: Routes.account,
        builder: (context, state) => BlocProvider(
          create: (context) => AuthCubit(GetIt.I<AuthUseCase>()),
          child: const AccountPrototypeScreen(),
        ),
      ),
      // Welcome, phone number and code share one SignInCubit, so the code page
      // knows the number. The cubit is closed when the user leaves these pages.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (context) => SignInCubit(GetIt.I<AuthUseCase>()),
          child: child,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.auth,
            builder: (context, state) => const AuthFeatureScreen(),
          ),
          GoRoute(
            path: Routes.authPhone,
            builder: (context, state) => const PhoneScreen(),
          ),
          GoRoute(
            path: Routes.authCode,
            builder: (context, state) => const CodeScreen(),
          ),
        ],
      ),
      // Name page and start page share one OnboardingCubit. The page that adds
      // another circle is the start page again, so it shares the cubit too.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (context) => OnboardingCubit(GetIt.I<OnboardingUseCase>()),
          child: child,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.onboarding,
            builder: (context, state) => const OnboardingFeatureScreen(),
          ),
          GoRoute(
            path: Routes.onboardingStart,
            builder: (context, state) => const StartScreen(),
          ),
          GoRoute(
            path: Routes.addCircle,
            builder: (context, state) => const StartScreen(addingCircle: true),
          ),
        ],
      ),
      // The three steps of the circle for your own care share one
      // CreateSelfCircleCubit, so going back keeps the answers. When the server
      // says the sign-in ended, any of the steps sends the user to sign-in.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (context) => CreateSelfCircleCubit(
            GetIt.I<CirclesUseCase>(),
            GetIt.I<HomeUseCase>(),
          )..loadAccount(),
          child: BlocListener<CreateSelfCircleCubit, CreateSelfCircleState>(
            listenWhen: (before, after) =>
                after.sessionEnded && !before.sessionEnded,
            listener: (context, state) => context.go(Routes.auth),
            child: child,
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.createSelfCircle,
            builder: (context, state) => const SelfCircleBasicsScreen(),
          ),
          GoRoute(
            path: Routes.createSelfCircleHealth,
            builder: (context, state) => const SelfCircleHealthScreen(),
          ),
          GoRoute(
            path: Routes.createSelfCircleAllergies,
            builder: (context, state) => const SelfCircleAllergiesScreen(),
          ),
        ],
      ),
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

  /// The page a phone is sent to instead of [location], or null when it may
  /// open [location]. The splash page, the sign-in pages and the debug
  /// gallery are open to everyone. Every other page needs the tokens
  /// ([hasTokens]); without them the phone is sent to the sign-in page.
  @visibleForTesting
  static String? signInRedirect(
    String location, {
    required bool hasTokens,
  }) {
    if (hasTokens) return null;
    final bool open = location == Routes.splash ||
        location == Routes.gallery ||
        location == Routes.auth ||
        location.startsWith('${Routes.auth}/');
    return open ? null : Routes.auth;
  }

  static StatefulShellBranch _branch(String path) {
    return StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: path,
          builder: (context, state) => const SizedBox.expand(),
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
