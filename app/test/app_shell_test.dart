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
import 'package:app/features/placeholder/placeholder_screen.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads the real translation file synchronously, so loading finishes inside
/// the test clock.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final String text = File('$path/${locale.languageCode}.json').readAsStringSync();
    return jsonDecode(text) as Map<String, dynamic>;
  }
}

/// A phone that is signed in. The router reads the tokens before it opens any
/// page that needs a sign-in.
class _SignedInTokens implements TokenStorage {
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> saveAccessToken(String accessToken) async {}

  @override
  Future<String?> readAccessToken() async => 'test-access-token';

  @override
  Future<String?> readRefreshToken() async => 'test-refresh-token';

  @override
  Future<void> clear() async {}
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
  Future<bool> hasSession() async => true;
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

Finder inPage(String text) =>
    find.descendant(of: find.byType(PlaceholderScreen), matching: find.text(text));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    GetIt.I.registerSingleton<TokenStorage>(_SignedInTokens());
    GetIt.I.registerSingleton<AuthUseCase>(
      AuthUseCase(_OfflineAuthRepository()),
    );
  });

  tearDownAll(() async {
    await GetIt.I.reset();
  });

  group('AppShell', () {
    testWidgets('shows the top bar actions, four tabs and the add button',
        (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.add_circle'.tr()), findsOneWidget);
      expect(find.byTooltip('tab.add'.tr()), findsOneWidget);
      for (final String key in <String>[
        'tab.today',
        'tab.plan',
        'tab.record',
        'tab.circle',
      ]) {
        expect(inBar(key.tr()), findsWidgets);
      }
    });

    testWidgets('every tab shows its page and keeps both bars',
        (WidgetTester tester) async {
      await pumpApp(tester);

      for (final String key in <String>[
        'tab.plan',
        'tab.record',
        'tab.circle',
        'tab.today',
      ]) {
        await tester.tap(inBar(key.tr()).first);
        await tester.pumpAndSettle();
        expect(inPage(key.tr()), findsOneWidget);
        expect(find.byType(AppBottomBar), findsOneWidget);
        expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      }
    });

    testWidgets('the add button opens the add sheet',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('add.title'.tr()), findsOneWidget);
    });

    testWidgets('account opens a standalone page and back returns to the shell',
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
    });
  });
}
