import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/account/domain/repositories/profile_repository_domain.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/circles_fakes.dart';
import '../support/home_fakes.dart';
import '../support/phone_fakes.dart';
import '../support/widget_harness.dart';

class _Auth extends Fake implements AuthRepositoryDomain {
  int signOuts = 0;

  @override
  Future<Result<bool, Failure>> signOut() async {
    signOuts++;
    return const Success(true);
  }
}

/// Answers every save with [result].
class _Profile implements ProfileRepositoryDomain {
  Result<void, Failure> result = const Success(null);

  @override
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) async => result;
}

void main() {
  group('OnboardingBack', () {
    late _Auth auth;
    late _Profile profile;
    late CirclesFakeRepository circles;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await EasyLocalization.ensureInitialized();
      GetIt.I
        ..registerSingleton<DoseReminders>(FakeDoseReminders())
        ..registerSingleton<CalendarSync>(FakeCalendarSync());
    });

    tearDownAll(() async {
      await GetIt.I.unregister<DoseReminders>();
      await GetIt.I.unregister<CalendarSync>();
    });

    setUp(() {
      auth = _Auth();
      profile = _Profile();
      circles = CirclesFakeRepository();
    });

    /// The first set-up as the code page opens it: the name page alone, with
    /// nothing under it.
    Future<GoRouter> open(
      WidgetTester tester, {
      String start = Routes.onboarding,
    }) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GoRouter router = GoRouter(
        initialLocation: start,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.auth,
            builder: (context, state) =>
                const Scaffold(body: Text('sign-in page')),
          ),
          GoRoute(
            path: Routes.today,
            builder: (context, state) =>
                const Scaffold(body: Text('today page')),
          ),
          GoRoute(
            path: Routes.authPhone,
            builder: (context, state) =>
                const Scaffold(body: Text('phone page')),
          ),
          ShellRoute(
            builder: (context, state, child) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => OnboardingCubit(ProfileUseCase(profile)),
                ),
                BlocProvider(create: (_) => AuthCubit(AuthUseCase(auth))),
                BlocProvider(
                  create: (_) => InboxCubit(
                    CirclesUseCase(circles),
                    HomeUseCase(HomeFakeRepository()),
                  )..load(),
                ),
              ],
              child: child,
            ),
            routes: <RouteBase>[
              GoRoute(
                path: Routes.onboarding,
                builder: (context, state) => const ProfileStepScreen(),
              ),
              GoRoute(
                path: Routes.onboardingStart,
                builder: (context, state) => const StartScreen(),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp.router(
              theme: AppTheme.lightTheme,
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    Finder back() => find.text('common.back'.tr());

    testWidgets('«رجوع» on the name page asks first, then signs out', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(back());
      await tester.pumpAndSettle();
      expect(find.text('onboarding.back_title'.tr()), findsOneWidget);
      expect(auth.signOuts, 0);

      // The alert's own «رجوع» confirms; it is the last one on screen.
      await tester.tap(back().last);
      await tester.pumpAndSettle();

      expect(auth.signOuts, 1);
      expect(find.text('phone page'), findsOneWidget);
      expect(find.byType(ProfileStepScreen), findsNothing);
    });

    testWidgets('«إلغاء» in the alert keeps the person signed in on the page', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(back());
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.cancel'.tr()));
      await tester.pumpAndSettle();

      expect(auth.signOuts, 0);
      expect(find.text('onboarding.back_title'.tr()), findsNothing);
      expect(find.byType(ProfileStepScreen), findsOneWidget);
    });

    testWidgets('«رجوع» on the start page returns to the name page as it was', (
      tester,
    ) async {
      final GoRouter router = await open(tester);
      await tester.enterText(find.byType(TextField).first, 'ريم');
      router.push(Routes.onboardingStart).ignore();
      await tester.pumpAndSettle();

      await tester.tap(back());
      await tester.pumpAndSettle();

      expect(find.byType(StartScreen), findsNothing);
      expect(find.text('ريم'), findsWidgets);
      expect(auth.signOuts, 0);
    });

    testWidgets('a save that finds the sign-in ended leaves for the sign-in', (
      tester,
    ) async {
      profile.result = const Error(SessionExpiredFailure());
      await open(tester);
      tester.element(find.byType(ProfileStepScreen)).read<OnboardingCubit>()
        ..firstNameChanged('ريم')
        ..lastNameChanged('الأحمدي')
        ..displayNameChanged('ريم')
        ..birthDateChanged(DateTime(1990, 3, 4))
        ..cityChanged('الرياض');

      await tester.tap(find.text('common.continue'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('sign-in page'), findsOneWidget);
      expect(find.text('error.session_ended'.tr()), findsNothing);
    });

    testWidgets('accepting an invitation on the start page opens «اليوم»', (
      tester,
    ) async {
      circles.inbox = Success(
        CircleInbox(
          sent: const [],
          received: const [],
          invitations: const <ReceivedInvitation>[
            ReceivedInvitation(id: 'inv-1', circleName: 'أمي نورة'),
          ],
        ),
      );
      await open(tester, start: Routes.onboardingStart);

      await tester.tap(find.text('circles.accept'.tr()));
      await tester.pumpAndSettle();

      expect(circles.invitationAnswers.single, ('inv-1', true));
      expect(find.text('today page'), findsOneWidget);
    });
  });
}
