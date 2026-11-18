import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/account_routes.dart';
import 'package:app/core/navigation/routes/auth_routes.dart';
import 'package:app/core/navigation/routes/care_routes.dart';
import 'package:app/core/navigation/routes/circle_routes.dart';
import 'package:app/core/navigation/routes/home_routes.dart';
import 'package:app/core/navigation/routes/onboarding_routes.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/core/navigation/routes/simplified_routes.dart';
import 'package:app/dev/component_gallery.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:app/features/auth/presentation/pages/splash_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Every page of the app, in the order the router matches them.
List<RouteBase> appRoutes() => <RouteBase>[
  GoRoute(
    path: Routes.splash,
    pageBuilder: iosPage(
      (context, state) => BlocProvider(
        create: (context) => SplashCubit(GetIt.I<AuthUseCase>())..decide(),
        child: const SplashScreen(),
      ),
    ),
  ),
  GoRoute(path: Routes.home, redirect: (context, state) => Routes.today),
  simplifiedShell(),
  homeShell(),
  ...careRoutes(),
  ...accountRoutes(),
  signInShell(),
  onboardingShell(),
  ...circleRoutes(),
  if (kDebugMode)
    GoRoute(
      path: Routes.gallery,
      pageBuilder: iosPage((context, state) => const ComponentGallery()),
    ),
];
