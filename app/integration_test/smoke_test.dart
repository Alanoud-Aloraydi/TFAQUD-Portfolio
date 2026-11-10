// The device smoke flow, run on Android emulators and iOS simulators by
// .github/workflows/device-matrix.yml:
//
//   flutter test integration_test/smoke_test.dart -d <device>
//
// It opens the signed-in app on offline repositories, visits each tab with
// the bottom bar, opens the add sheet and closes it with the system back,
// and schedules one real reminder on the phone.
import 'package:app/core/l10n/dose_reminder_texts.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../test/support/circles_fakes.dart';
import '../test/support/home_fakes.dart';
import '../test/support/phone_fakes.dart';
import 'smoke_fakes.dart';

/// The tabs in bar order, with the path each one opens.
const List<(String, String)> _tabs = <(String, String)>[
  ('tab.plan', Routes.plan),
  ('tab.record', Routes.record),
  ('tab.circle', Routes.circle),
  ('tab.today', Routes.today),
];

Future<void> _pumpApp(WidgetTester tester) async {
  AppRouter.router.go(Routes.today);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('ar')],
      path: 'assets/translations',
      startLocale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      saveLocale: false,
      child: Builder(
        builder: (BuildContext context) => MaterialApp.router(
          routerConfig: AppRouter.router,
          builder: (context, child) =>
              RepositoryProvider<PrivatePhotoRepository>.value(
                value: GetIt.I<PrivatePhotoRepository>(),
                child: child!,
              ),
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

/// The system back button (Android) or back gesture: the message the
/// engine sends Flutter for it.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final FakePhoneNotifications phone = FakePhoneNotifications();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
    ensureTimeZones();
    final HomeFakeRepository home = HomeFakeRepository()
      ..response = Success(
        homeData(
          circles: const <CareCircleSummary>[
            CareCircleSummary(
              id: 'one',
              name: 'Circle one',
              canManageMedications: true,
            ),
          ],
        ),
      );
    final GetIt di = GetIt.I;
    di.registerSingleton<TokenStorage>(SmokeSignedInTokens());
    di.registerSingleton<AuthUseCase>(AuthUseCase(SmokeAuthRepository()));
    di.registerSingleton<HomeUseCase>(HomeUseCase(home));
    di.registerSingleton<ProfileUseCase>(
      ProfileUseCase(SmokeProfileRepository()),
    );
    di.registerSingleton<CirclesUseCase>(
      CirclesUseCase(CirclesFakeRepository()),
    );
    di.registerSingleton<MedicationsUseCase>(
      MedicationsUseCase(SmokeMedicationsRepository()),
    );
    di.registerSingleton<MeasurementRepository>(SmokeMeasurementsRepository());
    di.registerSingleton<AppointmentRepository>(SmokeAppointmentsRepository());
    di.registerSingleton<PhoneNotifications>(phone);
    di.registerSingleton<DoseReminders>(
      DoseReminders(
        di<MedicationsUseCase>(),
        phone,
        texts: doseReminderTexts,
        measurements: di<MeasurementRepository>(),
        appointments: di<AppointmentRepository>(),
      ),
    );
    di.registerSingleton<CalendarSync>(SmokeCalendarSync());
    di.registerSingleton<PushRegistration>(
      PushRegistration(phone, (String token) async {}),
    );
    di.registerSingleton<PrayerTimesRepository>(
      PrayerTimesRepository(SmokePrayerTimes()),
    );
    di.registerSingleton<PrivatePhotoRepository>(SmokePhotoRepository());
  });

  tearDownAll(() => GetIt.I.reset());

  testWidgets('each tab opens from the bottom bar', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    expect(find.byType(AppBottomBar), findsOneWidget);
    // The Flutter bar on Android and on iOS before 26. iOS 26 and later
    // draws Apple's own tab bar, which a Flutter test cannot tap, so there
    // each tab opens through the router, as a tap on that bar does.
    final bool flutterBar = find
        .byType(CrystalNavigationBar)
        .evaluate()
        .isNotEmpty;
    if (defaultTargetPlatform == TargetPlatform.android) {
      expect(flutterBar, isTrue);
    }

    for (final (String label, String path) in _tabs) {
      if (flutterBar) {
        await tester.tap(
          find
              .descendant(
                of: find.byType(AppBottomBar),
                matching: find.text(label.tr()),
              )
              .first,
        );
      } else {
        AppRouter.router.go(path);
      }
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, path);
      expect(find.byType(AppBottomBar), findsOneWidget);
    }
  });

  testWidgets('the add sheet opens and the system back closes it', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final Finder medication = find.text('add.medication'.tr());
    expect(medication, findsNothing);

    await tester.tap(find.byTooltip('tab.add'.tr()));
    await tester.pumpAndSettle();
    expect(medication, findsOneWidget);

    await _systemBack(tester);
    expect(medication, findsNothing);
    expect(
      AppRouter.router.routeInformationProvider.value.uri.path,
      Routes.today,
    );
  });

  testWidgets('a reminder is scheduled on the phone', (
    WidgetTester tester,
  ) async {
    final PluginPhoneNotifications notifications = PluginPhoneNotifications();
    await notifications.initialize();
    const int id = 990001;
    await notifications.schedule(
      ScheduledNotification(
        id: id,
        at: DateTime.now().add(const Duration(hours: 1)),
        title: 'تفقّد',
        body: 'smoke',
        payload: 'smoke',
      ),
    );
    // Android keeps it without a permission. iOS may keep a request only
    // once notifications are allowed, and a test cannot answer that
    // question, so there the calls themselves must succeed.
    if (defaultTargetPlatform == TargetPlatform.android) {
      expect((await notifications.pending())[id], 'smoke');
    }
    await notifications.cancel(id);
    expect((await notifications.pending()).containsKey(id), isFalse);
  });
}
