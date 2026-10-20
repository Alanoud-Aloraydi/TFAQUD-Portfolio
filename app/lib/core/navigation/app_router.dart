import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/dev/component_gallery.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/pages/account_prototype_screen.dart';
import 'package:app/features/auth/presentation/pages/auth_feature_screen.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/onboarding_feature_screen.dart';
import 'package:app/features/placeholder/placeholder_screen.dart';
import 'package:app/features/shell/app_shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
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
      GoRoute(
        path: Routes.account,
        builder: (context, state) => BlocProvider(
          create: (context) => AuthCubit(GetIt.I<AuthUseCase>()),
          child: const AccountPrototypeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (context, state) => const AuthFeatureScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => BlocProvider(
          create: (context) => OnboardingCubit(GetIt.I<OnboardingUseCase>()),
          child: const OnboardingFeatureScreen(),
        ),
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
