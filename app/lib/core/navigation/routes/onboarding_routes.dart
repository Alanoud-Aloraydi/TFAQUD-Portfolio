import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

// Name page and start page share one OnboardingCubit. The page that adds
// another circle is the start page again, so it shares the cubit too.
// The start page also needs an InboxCubit: a brand-new person may
// already have an invitation waiting, answered right there. «رجوع»
// on the name page signs out (AuthCubit), back to the phone number.
// The providers are lazy: the page that adds a circle never reads the
// InboxCubit or the AuthCubit, so neither is created or loaded there.
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
