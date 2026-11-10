part of '../app_router.dart';

/// The account's cubit, reading the account; the account pages of both
/// modes share it.
AccountCubit _loadedAccountCubit() => AccountCubit(
  GetIt.I<CirclesUseCase>(),
  GetIt.I<ProfileUseCase>(),
  GetIt.I<AuthUseCase>(),
  GetIt.I<HomeUseCase>(),
)..load();

/// The account page and its edit page.
List<RouteBase> _accountRoutes() => <RouteBase>[
  // The account page: names, phone number, requests that wait for the
  // patient, sign-out (AuthCubit) and deleting the account.
  GoRoute(
    path: Routes.account,
    pageBuilder: _iosModalPage(
      (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => _loadedAccountCubit()),
          BlocProvider(create: (context) => AuthCubit(GetIt.I<AuthUseCase>())),
        ],
        child: const AccountScreen(),
      ),
    ),
  ),
  GoRoute(
    path: Routes.accountEdit,
    pageBuilder: _iosPage(
      (context, state) => BlocProvider(
        create: (context) => _loadedAccountCubit(),
        child: const AccountEditScreen(),
      ),
    ),
  ),
];

// Welcome, phone number and code share one SignInCubit, so the code page
// knows the number. The cubit is closed when the user leaves these pages.
ShellRoute _signInShell() => ShellRoute(
  pageBuilder: _iosShellPage(
    (context, state, child) => BlocProvider(
      create: (context) => SignInCubit(GetIt.I<AuthUseCase>()),
      child: child,
    ),
  ),
  routes: <RouteBase>[
    GoRoute(
      path: Routes.auth,
      redirect: _welcomeOnce,
      pageBuilder: _iosPage((context, state) => const AuthFeatureScreen()),
    ),
    GoRoute(
      path: Routes.authPhone,
      pageBuilder: _iosPage((context, state) => const PhoneScreen()),
    ),
    GoRoute(
      path: Routes.authCode,
      pageBuilder: _iosPage((context, state) => const CodeScreen()),
    ),
  ],
);

// Name page and start page share one OnboardingCubit. The page that adds
// another circle is the start page again, so it shares the cubit too.
// The start page also needs an InboxCubit: a brand-new person may
// already have an invitation waiting, answered right there. «رجوع»
// on the name page signs out (AuthCubit), back to the phone number.
// The providers are lazy: the page that adds a circle never reads the
// InboxCubit or the AuthCubit, so neither is created or loaded there.
ShellRoute _onboardingShell() => ShellRoute(
  pageBuilder: _iosShellPage(
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
      pageBuilder: _iosPage((context, state) => const ProfileStepScreen()),
    ),
    GoRoute(
      path: Routes.onboardingStart,
      pageBuilder: _iosPage((context, state) => const StartScreen()),
    ),
    GoRoute(
      path: Routes.addCircle,
      pageBuilder: _iosPage(
        (context, state) => const StartScreen(addingCircle: true),
      ),
    ),
  ],
);

/// The welcome shows once per install ([IntroMemory]). After it, a
/// signed-out phone opens on the phone number page, and what was the last
/// person's goes, as the welcome would have removed it.
Future<String?> _welcomeOnce(BuildContext context, GoRouterState state) async {
  if (!await IntroMemory.seen()) return null;
  unawaited(forgetSignedOutPerson());
  return Routes.authPhone;
}
