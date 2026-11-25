import 'package:app/app/dev/component_gallery.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/appointments/routing/appointment_routes.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:app/features/auth/presentation/pages/splash_screen.dart';
import 'package:app/features/circles/routing/circle_routes.dart';
import 'package:app/features/home/routing/home_routes.dart';
import 'package:app/features/home/routing/loaded_account_cubit.dart';
import 'package:app/features/medications/routing/medication_routes.dart';
import 'package:app/features/onboarding/routing/onboarding_routes.dart';
import 'package:app/features/simplified_mode/routing/simplified_routes.dart';
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

/// The pages of a circle's medicines, measurements and appointments, opened
/// from the home tabs. Each one loads what it shows for the circle in the
/// address.
List<RouteBase> careRoutes() => <RouteBase>[
  medicationNewRoute(),
  ...measurementRoutes(),
  ...appointmentRoutes(),
  ...medicationPlanRoutes(),
];

/// The account page and its edit page.
List<RouteBase> accountRoutes() => <RouteBase>[
  // The account page: names, phone number, requests that wait for the
  // patient, sign-out (AuthCubit) and deleting the account.
  GoRoute(
    path: Routes.account,
    pageBuilder: iosModalPage(
      (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => loadedAccountCubit()),
          BlocProvider(create: (context) => AuthCubit(GetIt.I<AuthUseCase>())),
        ],
        child: const AccountScreen(),
      ),
    ),
  ),
  GoRoute(
    path: Routes.accountEdit,
    pageBuilder: iosPage(
      (context, state) => BlocProvider(
        create: (context) => loadedAccountCubit(),
        child: const AccountEditScreen(),
      ),
    ),
  ),
];
