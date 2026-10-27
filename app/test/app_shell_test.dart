import 'dart:convert';
import 'dart:io';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_fakes.dart';

/// Reads the real translation file synchronously, so loading finishes inside
/// the test clock.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final String text = File('$path/${locale.languageCode}.json')
        .readAsStringSync();
    return jsonDecode(text) as Map<String, dynamic>;
  }
}

/// A phone that is signed in. The router reads the tokens before it opens any
/// page that needs a sign-in.
class _SignedInTokens implements TokenStorage {
  @override
  int get revision => 0;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> saveAccessToken(
    String accessToken, {
    int? expectedRevision,
  }) async {}

  @override
  Future<String?> readAccessToken() async => 'test-access-token';

  @override
  Future<String?> readRefreshToken() async => 'test-refresh-token';

  @override
  Future<void> clear({int? expectedRevision}) async {}
}

/// The account page builds an AuthCubit from the AuthUseCase. This repository
/// answers without a server; the tests here never press its buttons.
class _OfflineAuthRepository implements AuthRepositoryDomain {
  @override
  Future<Result<String, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async => Success('verification-id');

  @override
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) async => Success(const SignInResult(needsProfile: false));

  @override
  Future<Result<bool, Failure>> signOut() async => Success(true);

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() async =>
      const Success(SignInResult(needsProfile: false));
}

class _EmptyMedicationsRepository extends Fake
    implements MedicationsRepositoryDomain {
  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(
    String circleId,
  ) async => const Success([]);

  @override
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async => const Success([]);
}

Future<void> pumpApp(WidgetTester tester) async {
  AppRouter.router.go(Routes.today);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('ar')],
      path: 'assets/translations',
      startLocale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      saveLocale: false,
      assetLoader: const _FileAssetLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp.router(
          routerConfig: AppRouter.router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder inBar(String text) =>
    find.descendant(of: find.byType(AppBottomBar), matching: find.text(text));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final home = HomeFakeRepository();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    GetIt.I.registerSingleton<TokenStorage>(_SignedInTokens());
    GetIt.I.registerSingleton<AuthUseCase>(
      AuthUseCase(_OfflineAuthRepository()),
    );
    GetIt.I.registerSingleton<HomeUseCase>(HomeUseCase(home));
    GetIt.I.registerSingleton<MedicationsUseCase>(
      MedicationsUseCase(_EmptyMedicationsRepository()),
    );
  });

  setUp(() {
    home.response = Success(homeData());
    home.selections.clear();
  });

  tearDownAll(() async {
    await GetIt.I.reset();
  });

  group('AppShell', () {
    testWidgets('shows the top bar actions, four tabs and the add button', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.add_circle'.tr()), findsOneWidget);
      expect(find.byTooltip('tab.add'.tr()), findsOneWidget);
      final account = tester.getCenter(find.byTooltip('topbar.account'.tr()));
      final addCircle = tester.getCenter(
        find.byTooltip('topbar.add_circle'.tr()),
      );
      final bell = tester.getCenter(
        find.byTooltip('topbar.notifications'.tr()),
      );
      expect(
        (addCircle.dx - account.dx).abs(),
        lessThan((addCircle.dx - bell.dx).abs()),
      );
      for (final String key in <String>[
        'tab.today',
        'tab.plan',
        'tab.record',
        'tab.circle',
      ]) {
        expect(inBar(key.tr()), findsWidgets);
      }
    });

    testWidgets('tab navigation keeps both bars and the circle selection', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Circle two'));
      await tester.pumpAndSettle();

      for (final String key in <String>[
        'tab.plan',
        'tab.record',
        'tab.circle',
        'tab.today',
      ]) {
        await tester.tap(inBar(key.tr()).first);
        await tester.pumpAndSettle();
        expect(
          find.text(key.tr()).evaluate().length,
          inBar(key.tr()).evaluate().length,
        );
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          '/${key.split('.').last}',
        );
        final selected = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Circle two'),
        );
        expect(selected.selected, isTrue);
        expect(find.byType(AppBottomBar), findsOneWidget);
        expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      }
    });

    testWidgets('the add button opens the add sheet', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('add.title'.tr()), findsOneWidget);
    });

    testWidgets('no circles shows the real empty state and disabled actions', (
      WidgetTester tester,
    ) async {
      home.response = Success(homeData(circles: <CareCircleSummary>[]));
      await pumpApp(tester);
      expect(find.text('home.no_circles'.tr()), findsOneWidget);
      for (final key in ['topbar.add_circle', 'topbar.notifications']) {
        final button = tester.widget<IconButton>(
          find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == key.tr(),
          ),
        );
        expect(button.onPressed, isNull);
      }
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets(
      'account opens a standalone page and back returns to the shell',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await tester.tap(find.byTooltip('topbar.account'.tr()));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('topbar.account'.tr()),
          ),
          findsOneWidget,
        );
        expect(find.byType(AppBottomBar), findsNothing);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomBar), findsOneWidget);
      },
    );
  });
}
