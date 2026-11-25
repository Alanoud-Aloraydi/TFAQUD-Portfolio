// Name page and start page share one OnboardingCubit. The page that adds
// another circle is the start page again, so it shares the cubit too.
// The start page also needs an InboxCubit: a brand-new person may
// already have an invitation waiting, answered right there. «رجوع»
// on the name page signs out (AuthCubit), back to the phone number.
// The providers are lazy: the page that adds a circle never reads the
// InboxCubit or the AuthCubit, so neither is created or loaded there.
// Welcome, phone number and code share one SignInCubit, so the code page
// knows the number. The cubit is closed when the user leaves these pages.
import 'dart:async';

import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/app/services/signed_out.dart';
import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/pages/auth_feature_screen.dart';
import 'package:app/features/auth/presentation/pages/phone_screen.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

ShellRoute onboardingShell() => ShellRoute(
  pageBuilder: iosShellPage(
    (context, state, child) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => OnboardingCubit(GetIt.I<ProfileUseCase>()),
        ),
        BlocProvider(create: (context) => AuthCubit(GetIt.I<AuthUseCase>())),
        BlocProvider(
          create: (context) =>
              InboxCubit(GetIt.I<CirclesUseCase>(), GetIt.I<HomeUseCase>())
                ..load(),
        ),
      ],
      child: child,
    ),
  ),
  routes: <RouteBase>[
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: iosPage((context, state) => const ProfileStepScreen()),
    ),
    GoRoute(
      path: Routes.onboardingStart,
      pageBuilder: iosPage((context, state) => const StartScreen()),
    ),
    GoRoute(
      path: Routes.addCircle,
      pageBuilder: iosPage(
        (context, state) => const StartScreen(addingCircle: true),
      ),
    ),
  ],
);

ShellRoute signInShell() => ShellRoute(
  pageBuilder: iosShellPage(
    (context, state, child) => BlocProvider(
      create: (context) => SignInCubit(GetIt.I<AuthUseCase>()),
      child: child,
    ),
  ),
  routes: <RouteBase>[
    GoRoute(
      path: Routes.auth,
      redirect: _welcomeOnce,
      pageBuilder: iosPage((context, state) => const AuthFeatureScreen()),
    ),
    GoRoute(
      path: Routes.authPhone,
      pageBuilder: iosPage((context, state) => const PhoneScreen()),
    ),
    GoRoute(
      path: Routes.authCode,
      pageBuilder: iosPage((context, state) => const CodeScreen()),
    ),
  ],
);

/// The welcome shows once per install ([WelcomeMemory]). After it, a
/// signed-out phone opens on the phone number page, and what was the last
/// person's goes, as the welcome would have removed it.
Future<String?> _welcomeOnce(BuildContext context, GoRouterState state) async {
  if (!await GetIt.I<WelcomeMemory>().seen()) return null;
  unawaited(forgetSignedOutPerson());
  return Routes.authPhone;
}
