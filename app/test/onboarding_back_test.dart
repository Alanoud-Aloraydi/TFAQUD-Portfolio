import 'dart:convert';
import 'dart:io';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/onboarding_feature_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/circles_fakes.dart';
import 'support/home_fakes.dart';

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/ar.json').readAsStringSync())
          as Map<String, dynamic>;
}

class _Auth extends Fake implements AuthRepositoryDomain {
  int signOuts = 0;

  @override
  Future<Result<bool, Failure>> signOut() async {
    signOuts++;
    return const Success(true);
  }
}

class _Onboarding extends Fake implements OnboardingRepositoryDomain {}

class _Reminders extends Fake implements DoseReminders {
  @override
  Future<void> clear() async {}
}

class _Calendar extends Fake implements CalendarSync {
  @override
  Future<void> clear() async {}
}

void main() {
  late _Auth auth;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    GetIt.I
      ..registerSingleton<DoseReminders>(_Reminders())
      ..registerSingleton<CalendarSync>(_Calendar());
  });

  tearDownAll(() async {
    await GetIt.I.unregister<DoseReminders>();
    await GetIt.I.unregister<CalendarSync>();
  });

  setUp(() => auth = _Auth());

  /// The first set-up as the code page opens it: the name page alone, with
  /// nothing under it.
  Future<GoRouter> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final GoRouter router = GoRouter(
      initialLocation: Routes.onboarding,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.authPhone,
          builder: (context, state) => const Scaffold(body: Text('phone page')),
        ),
        ShellRoute(
          builder: (context, state, child) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    OnboardingCubit(OnboardingUseCase(_Onboarding())),
              ),
              BlocProvider(create: (_) => AuthCubit(AuthUseCase(auth))),
              BlocProvider(
                create: (_) => InboxCubit(
                  CirclesUseCase(CirclesFakeRepository()),
                  HomeUseCase(HomeFakeRepository()),
                ),
              ),
            ],
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
        assetLoader: const _Translations(),
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

  testWidgets('«رجوع» on the name page signs out, back to the phone number', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(back());
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    expect(find.text('phone page'), findsOneWidget);
    expect(find.byType(OnboardingFeatureScreen), findsNothing);
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
}
