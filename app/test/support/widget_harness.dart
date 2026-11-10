import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 12:00 in Riyadh on 9 November 2026, as a real instant.
final DateTime noonInRiyadh = DateTime.utc(2026, 11, 9, 9);

/// The Arabic texts, read from the asset file.
class TestTranslations extends AssetLoader {
  const TestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/ar.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// The private photos without any file or network: none stored.
class OfflinePhotoRepository implements PrivatePhotoRepository {
  final ValueNotifier<int> _changes = ValueNotifier<int>(0);

  @override
  Listenable get changes => _changes;

  @override
  Future<Uint8List?> load(String path) async => null;

  @override
  Future<void> save(String path, Uint8List bytes) async {}

  @override
  Future<void> remove(String path) async {}

  @override
  Future<void> chooseAvatar(String path, String code) async {}

  @override
  void clear() {}

  @override
  void dispose() => _changes.dispose();
}

/// Call in `setUpAll` of a widget test that shows texts.
Future<void> initTestLocalization() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
}

/// Shows [home] (or the pages of [router]) in Arabic under the patient's
/// [clock]: Riyadh at [noonInRiyadh] when left out. Person photos read
/// [photos], or an [OfflinePhotoRepository] with none stored.
Future<void> pumpArabic(
  WidgetTester tester, {
  Widget? home,
  RouterConfig<Object>? router,
  PatientClock? clock,
  PrivatePhotoRepository? photos,
}) async {
  assert((home == null) != (router == null), 'give a home or a router');
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final PatientClock patient =
      clock ?? PatientClock('Asia/Riyadh', clock: () => noonInRiyadh);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const TestTranslations(),
      child: RepositoryProvider<PrivatePhotoRepository>.value(
        value: photos ?? OfflinePhotoRepository(),
        child: Builder(
          builder: (context) => PatientClockScope(
            clock: patient,
            child: router == null
                ? MaterialApp(
                    theme: AppTheme.lightTheme,
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    home: home,
                  )
                : MaterialApp.router(
                    theme: AppTheme.lightTheme,
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    routerConfig: router,
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
