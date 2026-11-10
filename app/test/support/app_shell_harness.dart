import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/l10n/dose_reminder_texts.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/account/domain/repositories/profile_repository_domain.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/prayer_times/data/prayer_day_model.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'circles_fakes.dart';
import 'home_fakes.dart';
import 'phone_fakes.dart';
import 'widget_harness.dart';

/// A phone that is signed in. The router reads the tokens before it opens any
/// page that needs a sign-in.
/// Token storage that always holds a signed-in session.
class SignedInTokens implements TokenStorage {
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
/// The sign-in service answering without a server; counts sign-outs.
class OfflineAuthRepository implements AuthRepositoryDomain {
  /// How many times the phone was signed out.
  int signOuts = 0;

  @override
  Future<Result<CodeRequest, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async => const Success(
    CodeRequest(verificationId: 'verification-id', resendAfterSeconds: 30),
  );

  @override
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) async => Success(const SignInResult(needsProfile: false));

  @override
  Future<Result<bool, Failure>> signOut() async {
    signOuts++;
    return Success(true);
  }

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() async =>
      const Success(SignInResult(needsProfile: false));
}

/// A medications service with no plans and no doses.
class EmptyMedicationsRepository extends Fake
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

/// A measurements service with no plans, readings or tasks.
class EmptyMeasurementsRepository extends Fake
    implements MeasurementRepository {
  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Stream<String> get recorded => const Stream.empty();

  @override
  Future<List<MeasurementReading>> allReadings(String circleId) async =>
      const [];

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async => const [];

  @override
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async => const [];

  @override
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) async => const [];
}

/// An appointments service with no appointments.
class EmptyAppointmentsRepository extends Fake
    implements AppointmentRepository {
  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Future<List<CareAppointment>> appointments(String circleId) async => const [];
}

/// The prayer times source answering a fixed day.
class OfflinePrayerTimes extends Fake implements PrayerTimesRemoteDataSource {
  @override
  Future<PrayerDayModel> getToday(String circleId) async {
    final today = DateUtils.dateOnly(
      DateTime.now().toUtc().add(const Duration(hours: 3)),
    );
    return PrayerDayModel(
      PrayerDay(
        date: today,
        city: 'الرياض',
        times: const {
          Prayer.fajr: '05:00',
          Prayer.dhuhr: '12:00',
          Prayer.asr: '15:00',
          Prayer.maghrib: '18:00',
          Prayer.isha: '19:30',
        },
      ),
    );
  }
}

/// The start page builds an OnboardingCubit from the ProfileUseCase, and the
/// account page saves the names through it. It keeps what it was asked to save.
/// The profile service answering without a server; remembers what was saved.
class OfflineProfileRepository implements ProfileRepositoryDomain {
  /// The names that were saved, in order: first name, last name, display name.
  final List<List<String>> saved = <List<String>>[];

  /// The birth date and city sent with each save (null from the account page).
  final List<({DateTime? birthDate, String? city})> savedBasics =
      <({DateTime? birthDate, String? city})>[];
  Result<void, Failure> result = const Success(null);

  @override
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) async {
    saved.add(<String>[firstName, lastName, displayName]);
    savedBasics.add((birthDate: birthDate, city: city));
    return result;
  }
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
      assetLoader: const TestTranslations(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp.router(
          routerConfig: AppRouter.router,
          // As in `main.dart`: the photos, and the shown patient's clock
          // above the router so every page reads the same «now».
          builder: (context, child) =>
              RepositoryProvider<PrivatePhotoRepository>.value(
                value: GetIt.I<PrivatePhotoRepository>(),
                child: ValueListenableBuilder(
                  valueListenable: GetIt.I<ShownCircleClock>(),
                  builder: (context, clock, _) =>
                      PatientClockScope(clock: clock, child: child!),
                ),
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

/// The app's alert, whatever the type of its answer.
Finder findAlert() => find.byWidgetPredicate((Widget w) => w is AppAlert);

Finder inBar(String text) =>
    find.descendant(of: find.byType(AppBottomBar), matching: find.text(text));

/// Taps [text] in the open glass menu of the circle switcher.
Future<void> tapInSheet(WidgetTester tester, String text) async {
  await tester.tap(
    find.descendant(of: find.byType(GlassMenu), matching: find.text(text)),
  );
  await tester.pumpAndSettle();
}

/// Chooses a circle with the circle switcher in the middle of the top bar.
Future<void> chooseCircle(WidgetTester tester, String name) async {
  await tester.tap(find.byType(HomeWidget));
  await tester.pumpAndSettle();
  await tapInSheet(tester, name);
}

/// Opens «إضافة دائرة» from the circle switcher's menu.
Future<void> openAddCircle(WidgetTester tester) async {
  await tester.tap(find.byType(HomeWidget));
  await tester.pumpAndSettle();
  await tapInSheet(tester, 'topbar.add_circle'.tr());
}

/// A tall screen, so that no step or row needs scrolling in a test.
void tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The in-memory services behind the app, reset before every test by
/// [setUpShellApp].
final home = HomeFakeRepository();
final circles = CirclesFakeRepository();
final auth = OfflineAuthRepository();
final onboarding = OfflineProfileRepository();
final photoRepository = OfflinePhotoRepository();
final phone = FakePhoneNotifications();
final pushTokens = <String>[];

/// Registers the services the shell's pages read from GetIt (as
/// `configureDependencies` does in the app) with in-memory ones before
/// every test, and removes them after it, so no test sees
/// another's singletons. Call it first in `main` of a shell test.
void setUpShellApp() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    GetIt.I.registerSingleton<TokenStorage>(SignedInTokens());
    GetIt.I.registerSingleton<AuthUseCase>(AuthUseCase(auth));
    GetIt.I.registerSingleton<HomeUseCase>(HomeUseCase(home));
    GetIt.I.registerSingleton<ProfileUseCase>(ProfileUseCase(onboarding));
    GetIt.I.registerSingleton<CirclesUseCase>(CirclesUseCase(circles));
    GetIt.I.registerSingleton<MedicationsUseCase>(
      MedicationsUseCase(EmptyMedicationsRepository()),
    );
    GetIt.I.registerSingleton<MeasurementRepository>(
      EmptyMeasurementsRepository(),
    );
    GetIt.I.registerSingleton<AppointmentRepository>(
      EmptyAppointmentsRepository(),
    );
    // The phone's notifications in memory, and the dose reminders on them.
    GetIt.I.registerSingleton<PhoneNotifications>(phone);
    GetIt.I.registerSingleton<DoseReminders>(
      DoseReminders(
        GetIt.I<MedicationsUseCase>(),
        phone,
        texts: doseReminderTexts,
        measurements: GetIt.I<MeasurementRepository>(),
        appointments: GetIt.I<AppointmentRepository>(),
      ),
    );
    GetIt.I.registerSingleton<CalendarSync>(FakeCalendarSync());
    GetIt.I.registerSingleton<PushRegistration>(
      PushRegistration(phone, (String token) async => pushTokens.add(token)),
    );
    GetIt.I.registerSingleton<PrayerTimesRepository>(
      PrayerTimesRepository(OfflinePrayerTimes()),
    );
    GetIt.I.registerSingleton<PrivatePhotoRepository>(photoRepository);
    // The clock of the circle on screen; the home cubit sets it.
    GetIt.I.registerSingleton<ShownCircleClock>(ShownCircleClock());

    home.response = Success(homeData());
    home.selections.clear();
    circles.reset();
    auth.signOuts = 0;
    onboarding.saved.clear();
    onboarding.result = const Success(null);
  });

  tearDown(() => GetIt.I.reset());
}
