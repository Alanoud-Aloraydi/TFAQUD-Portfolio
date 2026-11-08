import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/pages/approved_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/circle_tab_screen.dart';
import 'package:app/features/circles/presentation/pages/emergency_card_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_screen.dart';
import 'package:app/features/circles/presentation/pages/notifications_screen.dart';
import 'package:app/features/circles/presentation/pages/patient_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/request_patient_screen.dart';
import 'package:app/features/circles/presentation/pages/request_reply_screen.dart';
import 'package:app/features/circles/presentation/pages/self_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/presentation/dose_reminder_texts.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/prayer_times/data/prayer_day_model.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:app/features/shell/widgets/glass_add_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/circles_fakes.dart';
import 'support/home_fakes.dart';
import 'support/phone_fakes.dart';

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

class _OfflinePhotoRepository implements PrivatePhotoRepository {
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

class _EmptyMeasurementsRepository extends Fake
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

class _EmptyAppointmentsRepository extends Fake
    implements AppointmentRepository {
  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Future<List<CareAppointment>> appointments(String circleId) async => const [];
}

/// The phone's own calendar is never touched here: the setting stays off
/// and every call does nothing. The home page and the account page ask
/// GetIt for it.
class _OffCalendarSync extends Fake implements CalendarSync {
  @override
  Future<bool> isEnabled(
    String circleId,
    CalendarSyncCategory category,
  ) async => false;

  @override
  Future<void> setEnabled(
    String circleId,
    CalendarSyncCategory category,
    bool value,
  ) async {}

  @override
  Future<void> sync(List<ReminderCircle> circles) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> clear() async {}
}

class _OfflinePrayerTimes extends Fake implements PrayerTimesRemoteDataSource {
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

/// The start page builds an OnboardingCubit from the OnboardingUseCase, and the
/// account page saves the names through it. It keeps what it was asked to save.
class _OfflineOnboardingRepository implements OnboardingRepositoryDomain {
  /// The names that were saved, in order: first name, last name, display name.
  final List<List<String>> saved = <List<String>>[];

  /// The birth date and city sent with each save (null from the account page).
  final List<({DateTime? birthDate, String? city})> savedBasics =
      <({DateTime? birthDate, String? city})>[];
  Result<bool, Failure> result = const Success(true);

  @override
  Future<Result<bool, Failure>> saveProfile({
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
      assetLoader: const _FileAssetLoader(),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final home = HomeFakeRepository();
  final circles = CirclesFakeRepository();
  final auth = _OfflineAuthRepository();
  final onboarding = _OfflineOnboardingRepository();
  final photoRepository = _OfflinePhotoRepository();
  final phone = FakePhoneNotifications();
  final pushTokens = <String>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    GetIt.I.registerSingleton<TokenStorage>(_SignedInTokens());
    GetIt.I.registerSingleton<AuthUseCase>(AuthUseCase(auth));
    GetIt.I.registerSingleton<HomeUseCase>(HomeUseCase(home));
    GetIt.I.registerSingleton<OnboardingUseCase>(OnboardingUseCase(onboarding));
    GetIt.I.registerSingleton<CirclesUseCase>(CirclesUseCase(circles));
    GetIt.I.registerSingleton<MedicationsUseCase>(
      MedicationsUseCase(_EmptyMedicationsRepository()),
    );
    GetIt.I.registerSingleton<MeasurementRepository>(
      _EmptyMeasurementsRepository(),
    );
    GetIt.I.registerSingleton<AppointmentRepository>(
      _EmptyAppointmentsRepository(),
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
    GetIt.I.registerSingleton<CalendarSync>(_OffCalendarSync());
    GetIt.I.registerSingleton<PushRegistration>(
      PushRegistration(phone, (String token) async => pushTokens.add(token)),
    );
    GetIt.I.registerSingleton<PrayerTimesRepository>(
      PrayerTimesRepository(_OfflinePrayerTimes()),
    );
    GetIt.I.registerSingleton<PrivatePhotoRepository>(photoRepository);
  });

  setUp(() {
    home.response = Success(homeData());
    home.selections.clear();
    circles.reset();
    auth.signOuts = 0;
    onboarding.saved.clear();
    onboarding.result = const Success(true);
  });

  tearDownAll(() async {
    await GetIt.I.reset();
  });

  group('AppShell', () {
    testWidgets('nothing dims the tab pages', (WidgetTester tester) async {
      await pumpApp(tester);

      // A tab page is see-through; a tinted barrier under it would darken
      // the whole tab and leave a lighter band under the top bar.
      expect(
        find.descendant(
          of: find.byType(FadingBranches),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is ModalBarrier && (widget.color?.a ?? 0) > 0,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('shows the top bar actions, four tabs and the add button', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsOneWidget);
      expect(find.byType(HomeWidget), findsOneWidget);
      expect(find.byTooltip('tab.add'.tr()), findsOneWidget);
      expect(
        tester.widget<GlassAddButton>(find.byType(GlassAddButton)).onPressed,
        isNull,
      );
      final account = tester.getCenter(find.byTooltip('topbar.account'.tr()));
      final switcher = tester.getCenter(find.byType(HomeWidget));
      final bell = tester.getCenter(
        find.byTooltip('topbar.notifications'.tr()),
      );
      // Right to left: the account at the start (right), the circle switcher
      // in the middle, the bell at the end (left).
      expect(account.dx, greaterThan(switcher.dx));
      expect(switcher.dx, greaterThan(bell.dx));
      for (final String key in <String>[
        'tab.today',
        'tab.plan',
        'tab.record',
        'tab.circle',
      ]) {
        expect(inBar(key.tr()), findsWidgets);
      }
    });

    testWidgets('every tab keeps both bars and selection', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await chooseCircle(tester, 'Circle two');

      for (final String key in <String>[
        'tab.plan',
        'tab.record',
        'tab.circle',
        'tab.today',
      ]) {
        await tester.tap(inBar(key.tr()).first);
        await tester.pumpAndSettle();
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          '/${key.split('.').last}',
        );
        expect(
          find.descendant(
            of: find.byType(HomeWidget),
            matching: find.text('Circle two'),
          ),
          findsOneWidget,
        );
        expect(find.byType(AppBottomBar), findsOneWidget);
        expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      }
    });

    testWidgets('an admin opens the add sheet', (WidgetTester tester) async {
      home.response = Success(
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
      await pumpApp(tester);

      // The empty Today page has its own add button with the same words, so
      // the sheet adds one more of them.
      final Finder addTitle = find.text('add.title'.tr());
      final int behindTheSheet = tester.widgetList(addTitle).length;

      await tester.tap(find.byTooltip('tab.add'.tr()));
      await tester.pumpAndSettle();

      expect(addTitle, findsNWidgets(behindTheSheet + 1));

      await tester.tap(find.text('add.medication'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('medications.add_title'.tr()), findsOneWidget);
      final save = find.text('medications.save_changes'.tr());
      await tester.tap(save);
      await tester.pump();
      expect(find.text('medications.field_required'.tr()), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('no circles shows the empty state with a way to create one', (
      WidgetTester tester,
    ) async {
      home.response = Success(homeData(circles: <CareCircleSummary>[]));
      await pumpApp(tester);
      expect(find.text('home.no_circles'.tr()), findsOneWidget);
      expect(find.text('home.create_circle'.tr()), findsOneWidget);
      // With no circle yet, the switcher is «إضافة دائرة» itself.
      final GlassCapsuleButton addCircle = tester.widget<GlassCapsuleButton>(
        find.descendant(
          of: find.byType(HomeWidget),
          matching: find.byType(GlassCapsuleButton),
        ),
      );
      expect(addCircle.label, 'topbar.add_circle'.tr());
      expect(addCircle.onPressed, isNotNull);
      final IconButton bell = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'topbar.notifications'.tr(),
        ),
      );
      // The bell works without a circle: an invitation or a request is how the
      // first circle can arrive. With nothing waiting there is no dot.
      expect(bell.onPressed, isNotNull);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets(
      'account rises as a modal page and its close button returns to the shell',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await tester.tap(find.byTooltip('topbar.account'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.text('account.title'.tr()), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);
        // A modal: it rises from the bottom, and has ✕ in place of «رجوع».
        final PageRoute<dynamic> route =
            ModalRoute.of(tester.element(find.byType(AccountScreen)))!
                as PageRoute<dynamic>;
        expect(route.fullscreenDialog, isTrue);
        expect(find.text('common.back'.tr()), findsNothing);

        await tester.tap(find.byTooltip('common.close'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomBar), findsOneWidget);
      },
    );
  });

  group('Circle creation for your own care', () {
    /// A tall screen, so that no step needs scrolling in a test.
    void tallPhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    /// Opens the first step from the "+" button, with "I manage my own care"
    /// chosen. Returns the cubit of the flow.
    Future<CreateCircleCubit> openFirstStep(WidgetTester tester) async {
      tallPhone(tester);
      await pumpApp(tester);
      await openAddCircle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding.self_title'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.continue'.tr()));
      await tester.pumpAndSettle();
      return tester
          .element(find.byType(SelfCircleBasicsScreen))
          .read<CreateCircleCubit>();
    }

    /// Fills what the date picker and the city sheet would fill (an account
    /// from before onboarding asked for them), then creates the circle.
    Future<void> finishFirstStep(
      WidgetTester tester,
      CreateCircleCubit cubit,
    ) async {
      cubit.birthDateChanged(DateTime(1964, 3, 12));
      cubit.cityChanged('الرياض');
      await tester.pump();
      await tester.tap(find.text('circles.create'.tr()));
      await tester.pumpAndSettle();
    }

    testWidgets('the "+" opens the start page with a back link and no skip', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await openAddCircle(tester);
      await tester.pumpAndSettle();

      expect(find.text('onboarding.start_title'.tr()), findsOneWidget);
      expect(find.text('onboarding.skip'.tr()), findsNothing);

      await tester.tap(find.text('common.back'.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('the empty state button opens the same start page', (
      WidgetTester tester,
    ) async {
      home.response = Success(homeData(circles: <CareCircleSummary>[]));
      await pumpApp(tester);
      await tester.tap(find.text('home.create_circle'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('onboarding.start_title'.tr()), findsOneWidget);
    });

    testWidgets('after onboarding only the name is asked and creates it', (
      WidgetTester tester,
    ) async {
      circles.account = Success(
        AccountSummary(
          firstName: 'Reem',
          lastName: 'Alahmadi',
          birthDate: DateTime(1990, 3, 4),
          city: 'الرياض',
        ),
      );
      await openFirstStep(tester);

      expect(find.text('circles.self_title'.tr()), findsOneWidget);
      // The birth date and city come from the account.
      expect(find.text('circles.birth_date'.tr()), findsNothing);
      expect(find.text('circles.city'.tr()), findsNothing);

      await tester.tap(find.text('circles.create'.tr()));
      await tester.pumpAndSettle();

      final request = circles.requests.single;
      expect(request.name, 'circles.preset.care'.tr());
      // Left out: the server reads them from the account.
      expect(request.birthDate, isNull);
      expect(request.city, isNull);
      expect(request.medicalProfile, isNull);
      expect(find.byType(AppBottomBar), findsOneWidget);
      expect(find.text('circles.created_notice'.tr()), findsOneWidget);
    });

    testWidgets('an account from before onboarding is asked for the rest', (
      WidgetTester tester,
    ) async {
      await openFirstStep(tester);

      expect(find.text('circles.self_title'.tr()), findsOneWidget);
      expect(find.text('circles.birth_date'.tr()), findsOneWidget);

      await tester.tap(find.text('circles.create'.tr()));
      await tester.pumpAndSettle();
      // The birth date and the city are missing; the page stays.
      expect(find.text('circles.field_required'.tr()), findsNWidgets(2));
      expect(find.text('circles.self_title'.tr()), findsOneWidget);
      expect(circles.requests, isEmpty);
    });

    testWidgets('a name of your own asks for the typed name', (
      WidgetTester tester,
    ) async {
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await tester.tap(find.text('circles.preset.other'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.custom_name'.tr()), findsOneWidget);

      cubit.birthDateChanged(DateTime(1964, 3, 12));
      cubit.cityChanged('الرياض');
      await tester.pump();
      await tester.tap(find.text('circles.create'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.field_required'.tr()), findsOneWidget);
      expect(find.text('circles.self_title'.tr()), findsOneWidget);
    });

    testWidgets('the city sheet searches, marks a city and confirms it', (
      WidgetTester tester,
    ) async {
      await openFirstStep(tester);
      await tester.tap(find.text('circles.city_hint'.tr()));
      await tester.pumpAndSettle();
      // The page below shows the same words as a hint, so look inside the sheet.
      expect(
        find.descendant(
          of: find.byType(CitySheet),
          matching: find.text('circles.city_sheet_title'.tr()),
        ),
        findsOneWidget,
      );

      final Finder confirm = find.widgetWithText(
        FilledButton,
        'circles.city_confirm'.tr(),
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(CitySheet),
          matching: find.byType(TextField),
        ),
        'ابها',
      );
      await tester.pumpAndSettle();
      expect(find.text('الرياض'), findsNothing);

      await tester.tap(find.text('أبها'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(find.byType(CitySheet), findsNothing);
      expect(find.text('أبها'), findsOneWidget);
    });

    testWidgets(
      'the birth date sheet writes every number with the digits 0-9',
      (WidgetTester tester) async {
        final CreateCircleCubit cubit = await openFirstStep(tester);
        await tester.tap(find.text('circles.birth_date_hint'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(BirthDateSheet), findsOneWidget);

        // No Arabic-Indic or Persian digit is shown anywhere in the sheet.
        final RegExp easternDigits = RegExp('[\u0660-\u0669\u06F0-\u06F9]');
        final Iterable<Text> shown = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(BirthDateSheet),
            matching: find.byType(Text),
          ),
        );
        expect(shown, isNotEmpty);
        for (final Text text in shown) {
          expect(
            easternDigits.hasMatch(text.data ?? ''),
            isFalse,
            reason: 'digits of "${text.data}"',
          );
        }

        // The wheel opens about 40 years back, on the first of January.
        await tester.tap(find.text('circles.date_confirm'.tr()));
        await tester.pumpAndSettle();

        final int year = DateTime.now().year - 40;
        expect(cubit.state.birthDate, DateTime(year, 1, 1));
        expect(find.text('1 ${'circles.months.1'.tr()} $year'), findsOneWidget);
      },
    );

    testWidgets('closing the birth date sheet keeps the field empty', (
      WidgetTester tester,
    ) async {
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await tester.tap(find.text('circles.birth_date_hint'.tr()));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(BirthDateSheet), findsNothing);
      expect(cubit.state.birthDate, isNull);
      expect(find.text('circles.birth_date_hint'.tr()), findsOneWidget);
    });

    testWidgets('an account that already has a circle is told at once', (
      WidgetTester tester,
    ) async {
      circles.account = const Success(
        AccountSummary(
          firstName: 'Reem',
          lastName: 'Alahmadi',
          patientCircleId: 'old-circle',
        ),
      );
      await openFirstStep(tester);

      expect(find.text('circles.already_title'.tr()), findsOneWidget);
      expect(find.text('circles.already_has_circle'.tr()), findsOneWidget);
      // Nothing to fill in: no form and no create button.
      expect(find.text('circles.birth_date'.tr()), findsNothing);
      expect(find.text('circles.create'.tr()), findsNothing);

      await tester.tap(find.text('circles.back_home'.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('one page creates the circle and opens the Circle tab', (
      WidgetTester tester,
    ) async {
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await finishFirstStep(tester, cubit);

      final request = circles.requests.single;
      expect(request.name, 'circles.preset.care'.tr());
      expect(request.birthDate, DateTime(1964, 3, 12));
      expect(request.city, 'الرياض');
      // The health answers are filled later in the medical file.
      expect(request.medicalProfile, isNull);
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('a refusal shows its text and keeps the user on the page', (
      WidgetTester tester,
    ) async {
      circles.created = const Error(AlreadyHasCircleFailure());
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await finishFirstStep(tester, cubit);

      expect(find.text('circles.already_has_circle'.tr()), findsOneWidget);
      expect(find.text('circles.self_title'.tr()), findsOneWidget);
      expect(find.byType(AppBottomBar), findsNothing);
    });
  });

  group('Circle creation for another person', () {
    /// A tall screen, so that no step needs scrolling in a test.
    void tallPhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    /// Opens the start page from the "+" button, with "I care for another
    /// person" and the answer to "does the patient use the app?" chosen, and
    /// presses continue.
    Future<void> openFlow(
      WidgetTester tester, {
      required bool patientUsesApp,
    }) async {
      tallPhone(tester);
      await pumpApp(tester);
      await openAddCircle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding.other_title'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          patientUsesApp
              ? 'onboarding.patient_uses_title'.tr()
              : 'onboarding.patient_no_title'.tr(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.continue'.tr()));
      await tester.pumpAndSettle();
    }

    Future<CreateCircleCubit> openPatientBasics(WidgetTester tester) async {
      await openFlow(tester, patientUsesApp: false);
      return tester
          .element(find.byType(PatientCircleBasicsScreen))
          .read<CreateCircleCubit>();
    }

    testWidgets(
      'the start page keeps continue off until the question is answered',
      (WidgetTester tester) async {
        tallPhone(tester);
        await pumpApp(tester);
        await openAddCircle(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('onboarding.other_title'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('onboarding.patient_question'.tr()), findsOneWidget);
        final Finder next = find.widgetWithText(
          FilledButton,
          'common.continue'.tr(),
        );
        expect(tester.widget<FilledButton>(next).onPressed, isNull);
      },
    );

    group('a patient who uses the app', () {
      testWidgets('the start page leads to the phone number page', (
        WidgetTester tester,
      ) async {
        await openFlow(tester, patientUsesApp: true);

        expect(find.byType(RequestPatientScreen), findsOneWidget);
        expect(find.text('circles.request_title'.tr()), findsOneWidget);
        // No name to choose: the note says how the circle will be named.
        // Then the mode and the note about the patient's consent.
        expect(find.text('circles.request_name_note'.tr()), findsOneWidget);
        expect(find.text('circles.mode_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.mode_detailed'.tr()), findsOneWidget);
        expect(find.text('circles.request_notice'.tr()), findsOneWidget);
      });

      testWidgets('a wrong number sends nothing and stays on the page', (
        WidgetTester tester,
      ) async {
        await openFlow(tester, patientUsesApp: true);
        await tester.enterText(find.byType(TextField), '1234');
        await tester.pump();
        await tester.tap(find.text('circles.send_request'.tr()));
        await tester.pumpAndSettle();

        expect(circles.sentRequests, isEmpty);
        expect(find.text('circles.request_title'.tr()), findsOneWidget);
        expect(find.text('circles.request_waiting_title'.tr()), findsNothing);
      });

      testWidgets(
        'the number is written in English digits and the request is sent',
        (WidgetTester tester) async {
          await openFlow(tester, patientUsesApp: true);
          // An Arabic keyboard types Arabic-Indic digits.
          await tester.enterText(find.byType(TextField), '٥٠١٢٣٤٥٦٧');
          await tester.pump();
          await tester.tap(find.text('circles.mode_detailed'.tr()));
          await tester.pump();
          await tester.tap(find.text('circles.send_request'.tr()));
          await tester.pumpAndSettle();

          final request = circles.sentRequests.single;
          expect(request.patientPhoneNumber, '+966501234567');
          // The patient names the circle; the request carries no name.
          expect(request.circleLabel, isNull);
          expect(request.proposedAppMode.name, 'detailed');
        },
      );

      testWidgets('the waiting page replaces the form and goes back home', (
        WidgetTester tester,
      ) async {
        await openFlow(tester, patientUsesApp: true);
        await tester.enterText(find.byType(TextField), '501234567');
        await tester.pump();
        await tester.tap(find.text('circles.send_request'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.request_waiting_title'.tr()), findsOneWidget);
        expect(find.text('circles.request_waiting_body'.tr()), findsOneWidget);
        expect(find.text('+966 50 123 4567'), findsOneWidget);
        expect(
          find.text('circles.request_status_pending'.tr()),
          findsOneWidget,
        );
        // The form is gone.
        expect(find.text('circles.send_request'.tr()), findsNothing);

        await tester.tap(find.text('circles.request_back'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomBar), findsOneWidget);
      });

      testWidgets('a request that the patient already accepted says so', (
        WidgetTester tester,
      ) async {
        circles.sent = const Success(
          SentCircleRequest(
            id: 'request-1',
            patientPhoneNumber: '+966501234567',
            circleLabel: 'أمي',
            proposedAppMode: CircleAppMode.simplified,
            status: CircleRequestStatus.accepted,
          ),
        );
        await openFlow(tester, patientUsesApp: true);
        await tester.enterText(find.byType(TextField), '501234567');
        await tester.pump();
        await tester.tap(find.text('circles.send_request'.tr()));
        await tester.pumpAndSettle();

        expect(
          find.text('circles.request_accepted_title'.tr()),
          findsOneWidget,
        );
        expect(
          find.text('circles.request_status_accepted'.tr()),
          findsOneWidget,
        );
      });

      testWidgets('a refusal shows its text and keeps the form', (
        WidgetTester tester,
      ) async {
        circles.sent = const Error(SelfRequestFailure());
        await openFlow(tester, patientUsesApp: true);
        await tester.enterText(find.byType(TextField), '501234567');
        await tester.pump();
        await tester.tap(find.text('circles.send_request'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.self_request'.tr()), findsOneWidget);
        expect(find.text('circles.send_request'.tr()), findsOneWidget);
        expect(find.text('circles.request_waiting_title'.tr()), findsNothing);
      });
    });

    group('a patient who does not use the app', () {
      testWidgets('the start page leads to the data of the patient', (
        WidgetTester tester,
      ) async {
        await openPatientBasics(tester);

        expect(find.text('circles.patient_title'.tr()), findsOneWidget);
        expect(find.text('circles.patient_first_name'.tr()), findsOneWidget);
        expect(find.text('circles.patient_last_name'.tr()), findsOneWidget);
        // The name of the signed-in account is not shown: the patient's names
        // are typed.
        expect(find.text('Reem Alahmadi'), findsNothing);
      });

      testWidgets('the missing answers are marked and the step stays', (
        WidgetTester tester,
      ) async {
        await openPatientBasics(tester);
        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        // The two names, the birth date and the city.
        expect(find.text('circles.field_required'.tr()), findsNWidgets(4));
        expect(find.text('circles.patient_title'.tr()), findsOneWidget);
      });

      testWidgets(
        'shows how the circle will be named while the name is typed',
        (WidgetTester tester) async {
          await openPatientBasics(tester);
          // Nobody names it: «دائرة» and the patient's first name.
          expect(find.text('circles.shared_name_hint'.tr()), findsOneWidget);

          await tester.enterText(find.byType(TextField).first, 'نورة');
          await tester.pump();
          final String name = 'circles.shared_name'.tr(args: <String>['نورة']);
          expect(
            find.text('circles.name_preview'.tr(args: <String>[name])),
            findsOneWidget,
          );
        },
      );

      testWidgets('the city sheet asks for the city of the patient', (
        WidgetTester tester,
      ) async {
        await openPatientBasics(tester);
        await tester.tap(find.text('circles.patient_city_hint'.tr()));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(CitySheet),
            matching: find.text('circles.patient_city_sheet_title'.tr()),
          ),
          findsOneWidget,
        );
      });

      testWidgets('one page creates the circle and opens the Circle tab', (
        WidgetTester tester,
      ) async {
        final CreateCircleCubit cubit = await openPatientBasics(tester);
        await tester.enterText(find.byType(TextField).at(0), 'نورة');
        await tester.enterText(find.byType(TextField).at(1), 'العتيبي');
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();
        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        final created = circles.patientCircles.single;
        expect(created.name, 'circles.shared_name'.tr(args: <String>['نورة']));
        expect(created.patientFirstName, 'نورة');
        expect(created.patientLastName, 'العتيبي');
        expect(created.birthDate, DateTime(1954, 6, 5));
        expect(created.city, 'بريدة');
        expect(created.medicalProfile, isNull);
        expect(circles.requests, isEmpty);
        expect(find.byType(AppBottomBar), findsOneWidget);
      });

      testWidgets('a refusal shows its text and keeps the user on the page', (
        WidgetTester tester,
      ) async {
        circles.createdPatient = const Error(ModeConflictFailure());
        final CreateCircleCubit cubit = await openPatientBasics(tester);
        await tester.enterText(find.byType(TextField).at(0), 'نورة');
        await tester.enterText(find.byType(TextField).at(1), 'العتيبي');
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();

        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.mode_conflict'.tr()), findsOneWidget);
        expect(find.text('circles.patient_title'.tr()), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);
      });
    });
  });

  group('Notifications', () {
    /// A tall screen, so that no step needs scrolling in a test.
    void tallPhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    CircleInbox inboxOf({
      List<SentCircleRequest> sent = const <SentCircleRequest>[],
      List<ReceivedCircleRequest> received = const <ReceivedCircleRequest>[],
      List<ReceivedInvitation> invitations = const <ReceivedInvitation>[],
    }) => CircleInbox(sent: sent, received: received, invitations: invitations);

    /// The bell as the top bar names it for [count] things that wait.
    Finder bell(int count) => find.byTooltip(
      count == 0
          ? 'topbar.notifications'.tr()
          : 'topbar.notifications_new'.tr(args: <String>['$count']),
    );

    Future<void> openNotifications(WidgetTester tester, int waiting) async {
      tallPhone(tester);
      await pumpApp(tester);
      await tester.tap(bell(waiting));
      await tester.pumpAndSettle();
    }

    final CircleInbox oneOfEach = inboxOf(
      received: const <ReceivedCircleRequest>[
        CirclesFakeRepository.askedOfNoura,
      ],
      invitations: const <ReceivedInvitation>[
        CirclesFakeRepository.invitedByKhaled,
      ],
    );

    testWidgets('the bell shows a dot and says how many things wait', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(oneOfEach);
      await pumpApp(tester);

      expect(find.byType(Badge), findsOneWidget);
      expect(bell(2), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsNothing);
    });

    testWidgets('with nothing waiting there is no dot', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(Badge), findsNothing);
      expect(bell(0), findsOneWidget);
    });

    testWidgets('a request the person already agreed to still counts', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          received: const <ReceivedCircleRequest>[
            CirclesFakeRepository.agreedByNoura,
          ],
        ),
      );
      await pumpApp(tester);
      expect(bell(1), findsOneWidget);
    });

    testWidgets('the bell opens the page with the invitation and the request', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(oneOfEach);
      await openNotifications(tester, 2);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      // The bell's page is a modal too: it rises from the bottom.
      final PageRoute<dynamic> route =
          ModalRoute.of(tester.element(find.byType(NotificationsScreen)))!
              as PageRoute<dynamic>;
      expect(route.fullscreenDialog, isTrue);
      expect(
        find.text('circles.needs_reply'.tr(args: <String>['2'])),
        findsOneWidget,
      );
      expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
      expect(
        find.text(
          'circles.invitation_body_by'.tr(args: <String>['خالد', 'أمي نورة']),
        ),
        findsOneWidget,
      );
      expect(find.text('circles.request_card_title'.tr()), findsOneWidget);
      expect(
        find.text(
          'circles.request_card_body'.tr(args: <String>['سارة الحربي']),
        ),
        findsOneWidget,
      );
      expect(find.text('circles.view_request'.tr()), findsOneWidget);
    });

    testWidgets('the bell opens a page that says nothing waits', (
      WidgetTester tester,
    ) async {
      await openNotifications(tester, 0);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
    });

    testWidgets('a request the patient declined is told under the events', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          sent: const <SentCircleRequest>[
            SentCircleRequest(
              id: 'request-1',
              patientPhoneNumber: '+966501234567',
              circleLabel: 'أمي',
              proposedAppMode: CircleAppMode.simplified,
              status: CircleRequestStatus.declined,
            ),
          ],
        ),
      );
      // A declined request needs no answer, so there is no dot.
      await openNotifications(tester, 0);

      expect(find.text('circles.events_title'.tr()), findsOneWidget);
      expect(find.text('circles.declined_title'.tr()), findsOneWidget);
      expect(find.text('circles.declined_body'.tr()), findsOneWidget);
      expect(find.text('+966 50 123 4567'), findsOneWidget);
      expect(find.text('circles.inbox_empty'.tr()), findsNothing);
    });

    testWidgets('a request still waiting for the patient is not an event', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          sent: const <SentCircleRequest>[CirclesFakeRepository.waitingRequest],
        ),
      );
      await openNotifications(tester, 0);

      expect(find.text('circles.events_title'.tr()), findsNothing);
      expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
    });

    testWidgets(
      'accepting an invitation sends the answer and clears the card',
      (WidgetTester tester) async {
        circles.inbox = Success(
          inboxOf(
            invitations: const <ReceivedInvitation>[
              CirclesFakeRepository.invitedByKhaled,
            ],
          ),
        );
        await openNotifications(tester, 1);
        // The server no longer lists the invitation once it was answered.
        circles.inbox = const Success(CircleInbox.empty());

        await tester.tap(find.text('circles.accept'.tr()));
        await tester.pumpAndSettle();

        expect(circles.invitationAnswers.single, ('invitation-1', true));
        expect(find.text('circles.invitation_title'.tr()), findsNothing);
        expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
      },
    );

    testWidgets('declining an invitation sends "no"', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          invitations: const <ReceivedInvitation>[
            CirclesFakeRepository.invitedByKhaled,
          ],
        ),
      );
      circles.invitationReplied = const Success<String?, Failure>(null);
      await openNotifications(tester, 1);
      circles.inbox = const Success(CircleInbox.empty());

      await tester.tap(find.text('circles.decline'.tr()));
      await tester.pumpAndSettle();

      expect(circles.invitationAnswers.single, ('invitation-1', false));
      expect(find.text('circles.invitation_title'.tr()), findsNothing);
    });

    testWidgets('a refused answer shows its text and keeps the card', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        inboxOf(
          invitations: const <ReceivedInvitation>[
            CirclesFakeRepository.invitedByKhaled,
          ],
        ),
      );
      circles.invitationReplied = const Error(RequestUnavailableFailure());
      await openNotifications(tester, 1);

      await tester.tap(find.text('circles.accept'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('circles.request_unavailable'.tr()), findsOneWidget);
      expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
    });

    testWidgets('a person who cannot be reached sees a retry button', (
      WidgetTester tester,
    ) async {
      tallPhone(tester);
      await pumpApp(tester);
      // The page reads the list again, and that read fails.
      circles.inbox = const Error(NetworkFailure());
      await tester.tap(bell(0));
      await tester.pumpAndSettle();

      expect(find.text('error.network'.tr()), findsOneWidget);
      circles.inbox = Success(oneOfEach);
      await tester.tap(find.text('auth.retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
    });

    group('a request from someone else', () {
      Future<void> openRequest(WidgetTester tester) async {
        circles.inbox = Success(oneOfEach);
        await openNotifications(tester, 2);
        await tester.tap(find.text('circles.view_request'.tr()));
        await tester.pumpAndSettle();
      }

      testWidgets('the request page says who asks and what is asked', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);

        expect(find.byType(RequestReplyScreen), findsOneWidget);
        expect(find.text('circles.reply_title'.tr()), findsOneWidget);
        expect(find.text('سارة الحربي'), findsOneWidget);
        // No circle name yet: the patient names it after agreeing.
        expect(find.text('أمي نورة'), findsNothing);
        expect(find.text('circles.mode_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.reply_body_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.reply_decline_note'.tr()), findsOneWidget);
        expect(find.text('circles.accept_request'.tr()), findsOneWidget);
        expect(find.text('circles.decline'.tr()), findsOneWidget);
      });

      testWidgets('the detailed mode is explained in its own words', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(
          inboxOf(
            received: const <ReceivedCircleRequest>[
              ReceivedCircleRequest(
                id: 'request-in-2',
                status: CircleRequestStatus.pending,
                circleLabel: 'أبي',
                circleName: 'أبي سعد',
                proposedAppMode: CircleAppMode.detailed,
                requesterName: 'خالد',
              ),
            ],
          ),
        );
        await openNotifications(tester, 1);
        await tester.tap(find.text('circles.view_request'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.mode_detailed'.tr()), findsOneWidget);
        expect(find.text('circles.reply_body_detailed'.tr()), findsOneWidget);
        expect(find.text('circles.reply_body_simplified'.tr()), findsNothing);
      });

      testWidgets('agreeing sends "yes" and opens the page of the basic data', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);

        await tester.tap(find.text('circles.accept_request'.tr()));
        await tester.pumpAndSettle();

        expect(circles.requestAnswers.single, ('request-in-1', true));
        expect(find.byType(RequestReplyScreen), findsNothing);
        expect(find.byType(ApprovedCircleBasicsScreen), findsOneWidget);
        // The patient names the circle with the chips of their own circle;
        // the name is the account's.
        expect(find.text('circles.preset.care'.tr()), findsOneWidget);
        expect(find.text('circles.name_hint'.tr()), findsOneWidget);
        expect(find.text('أمي نورة'), findsNothing);
        expect(find.text('Reem Alahmadi'), findsOneWidget);
        // Nothing was created yet: the circle exists after the last step.
        expect(circles.completions, isEmpty);
      });

      testWidgets('declining sends "no" and goes back to the notifications', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);
        circles.replied = const Success(CircleRequestStatus.declined);
        circles.inbox = Success(
          inboxOf(
            invitations: const <ReceivedInvitation>[
              CirclesFakeRepository.invitedByKhaled,
            ],
          ),
        );

        await tester.tap(find.text('circles.decline'.tr()));
        await tester.pumpAndSettle();

        expect(circles.requestAnswers.single, ('request-in-1', false));
        expect(find.byType(RequestReplyScreen), findsNothing);
        expect(find.byType(NotificationsScreen), findsOneWidget);
        // The page read the list again: the request is gone.
        expect(find.text('circles.request_card_title'.tr()), findsNothing);
        expect(find.text('circles.invitation_title'.tr()), findsOneWidget);
      });

      testWidgets('a request that is gone shows its text and stays', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);
        circles.replied = const Error(RequestUnavailableFailure());

        await tester.tap(find.text('circles.accept_request'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(RequestReplyScreen), findsOneWidget);
        expect(find.text('circles.request_unavailable'.tr()), findsOneWidget);
        expect(find.byType(ApprovedCircleBasicsScreen), findsNothing);
      });

      testWidgets('going back leaves the request unanswered', (
        WidgetTester tester,
      ) async {
        await openRequest(tester);

        await tester.tap(find.text('common.back'.tr()));
        await tester.pumpAndSettle();

        expect(circles.requestAnswers, isEmpty);
        expect(find.byType(NotificationsScreen), findsOneWidget);
        expect(find.text('circles.view_request'.tr()), findsOneWidget);
      });
    });

    group('a request the person agreed to', () {
      final CircleInbox agreed = inboxOf(
        received: const <ReceivedCircleRequest>[
          CirclesFakeRepository.agreedByNoura,
        ],
      );

      testWidgets('waits for the basic data on the page', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);

        expect(find.text('circles.complete_card_title'.tr()), findsOneWidget);
        expect(
          find.text(
            'circles.complete_card_body'.tr(args: <String>['سارة الحربي']),
          ),
          findsOneWidget,
        );
        expect(find.text('circles.view_request'.tr()), findsNothing);
      });

      testWidgets('continue opens the basic data page', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);

        await tester.tap(find.text('common.continue'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(ApprovedCircleBasicsScreen), findsOneWidget);
        expect(find.text('circles.preset.health'.tr()), findsOneWidget);
      });

      testWidgets('one tap creates the circle from the request', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);
        await tester.tap(find.text('common.continue'.tr()));
        await tester.pumpAndSettle();

        // An account from before onboarding gives its birth date and city
        // here. The date and the city sheets are covered by the first flow.
        final CreateCircleCubit cubit = tester
            .element(find.byType(ApprovedCircleBasicsScreen))
            .read<CreateCircleCubit>();
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();
        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        expect(circles.completedIds, <String>['request-in-1']);
        final completion = circles.completions.single;
        // The first chip is chosen unless the patient picks another.
        expect(completion.name, 'circles.preset.care'.tr());
        expect(completion.birthDate, DateTime(1954, 6, 5));
        expect(completion.city, 'بريدة');
        expect(completion.medicalProfile, isNull);
        // The patient's circle was made from the request, not by a new one.
        expect(circles.requests, isEmpty);
        expect(circles.patientCircles, isEmpty);
        expect(find.byType(AppBottomBar), findsOneWidget);
      });

      testWidgets('canceling asks first and keeps the request on "no"', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);

        await tester.tap(find.text('circles.cancel_request'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('circles.cancel_confirm_title'.tr()), findsOneWidget);
        expect(
          find.text('circles.cancel_confirm_body_patient'.tr()),
          findsOneWidget,
        );

        await tester.tap(find.text('circles.cancel_confirm_no'.tr()));
        await tester.pumpAndSettle();

        expect(circles.canceledIds, isEmpty);
        expect(find.text('circles.complete_card_title'.tr()), findsOneWidget);
      });

      testWidgets(
        'canceling on "yes" cancels this request and clears the card',
        (WidgetTester tester) async {
          circles.inbox = Success(agreed);
          await openNotifications(tester, 1);
          circles.inbox = const Success(CircleInbox.empty());

          await tester.tap(find.text('circles.cancel_request'.tr()));
          await tester.pumpAndSettle();
          await tester.tap(find.text('circles.cancel_confirm_yes'.tr()));
          await tester.pumpAndSettle();

          expect(circles.canceledIds, <String>['request-in-1']);
          expect(find.text('circles.complete_card_title'.tr()), findsNothing);
          expect(find.text('circles.inbox_empty'.tr()), findsOneWidget);
        },
      );
    });

    group('pages that need a request', () {
      testWidgets(
        'the request page opened without a request goes to the list',
        (WidgetTester tester) async {
          await pumpApp(tester);
          AppRouter.router.go(Routes.replyRequest);
          await tester.pumpAndSettle();

          expect(find.byType(RequestReplyScreen), findsNothing);
          expect(find.byType(NotificationsScreen), findsOneWidget);
        },
      );

      for (final String route in <String>[Routes.completeRequest]) {
        testWidgets('$route opened without a request goes to the list', (
          WidgetTester tester,
        ) async {
          await pumpApp(tester);
          AppRouter.router.go(route);
          await tester.pumpAndSettle();

          expect(find.byType(ApprovedCircleBasicsScreen), findsNothing);
          expect(find.byType(NotificationsScreen), findsOneWidget);
        });
      }
    });
  });

  group('Account page', () {
    /// A tall screen, so that no row needs scrolling in a test.
    void tallPhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> openAccount(WidgetTester tester) async {
      tallPhone(tester);
      await pumpApp(tester);
      await tester.tap(find.byTooltip('topbar.account'.tr()));
      await tester.pumpAndSettle();
    }

    Future<void> openSheet(WidgetTester tester, String rowLabel) async {
      await tester.tap(find.text(rowLabel));
      await tester.pumpAndSettle();
    }

    /// The one «تعديل» button at the top of the page.
    Future<void> openEdit(WidgetTester tester) async {
      await tester.tap(find.byTooltip('account.edit'.tr()));
      await tester.pumpAndSettle();
    }

    final DateTime fiveDaysAgo = DateTime.now().subtract(
      const Duration(days: 5, hours: 1),
    );

    testWidgets('shows the names, the phone number and the sign-out rows', (
      WidgetTester tester,
    ) async {
      await openAccount(tester);

      expect(find.text('account.my_data'.tr()), findsOneWidget);
      expect(find.text('account.display_name'.tr()), findsOneWidget);
      expect(find.text('Reem'), findsOneWidget);
      expect(find.text('account.full_name'.tr()), findsOneWidget);
      // The full name is on the card above the rows and in its row.
      expect(find.text('Reem Alahmadi'), findsNWidgets(2));
      expect(find.text('account.phone'.tr()), findsOneWidget);
      // The phone number is on the card above the rows and in its row.
      expect(find.text('+966 50 123 4567'), findsNWidgets(2));
      expect(find.text('account.medical_note'.tr()), findsOneWidget);
      expect(find.text('auth.sign_out'.tr()), findsOneWidget);
      expect(find.text('account.delete_account'.tr()), findsOneWidget);
      // No request waits, so there is no such list.
      expect(find.text('account.awaiting_title'.tr()), findsNothing);
    });

    testWidgets('a failure to load can be tried again', (
      WidgetTester tester,
    ) async {
      circles.account = const Error(NetworkFailure());
      await openAccount(tester);
      expect(find.text('error.network'.tr()), findsOneWidget);
      expect(find.text('account.my_data'.tr()), findsNothing);

      circles.account = const Success(CirclesFakeRepository.reem);
      await tester.tap(find.text('auth.retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('account.my_data'.tr()), findsOneWidget);
    });

    testWidgets('lists the circles that wait for the patient', (
      WidgetTester tester,
    ) async {
      circles.inbox = Success(
        CircleInbox(
          sent: <SentCircleRequest>[
            SentCircleRequest(
              id: 'request-1',
              patientPhoneNumber: '+966507654321',
              circleLabel: 'أمي',
              proposedAppMode: CircleAppMode.simplified,
              status: CircleRequestStatus.pending,
              createdAt: fiveDaysAgo,
            ),
            const SentCircleRequest(
              id: 'request-2',
              patientPhoneNumber: '+966501112233',
              circleLabel: 'أبي',
              proposedAppMode: CircleAppMode.detailed,
              status: CircleRequestStatus.accepted,
            ),
            const SentCircleRequest(
              id: 'request-3',
              patientPhoneNumber: '+966504445566',
              circleLabel: 'خالتي',
              proposedAppMode: CircleAppMode.simplified,
              status: CircleRequestStatus.declined,
            ),
          ],
          received: const <ReceivedCircleRequest>[],
          invitations: const <ReceivedInvitation>[],
        ),
      );
      await openAccount(tester);

      expect(find.text('account.awaiting_title'.tr()), findsOneWidget);
      // Each row shows the number: the circle has no name until the patient
      // names it.
      expect(find.text('+966 50 765 4321'), findsOneWidget);
      expect(find.text('+966 50 111 2233'), findsOneWidget);
      expect(find.text('أمي'), findsNothing);
      // The number of days is written 0-9.
      expect(
        find.text('account.sent_days_few'.tr(args: <String>['5'])),
        findsOneWidget,
      );
      expect(find.text('circles.request_status_pending'.tr()), findsOneWidget);
      expect(find.text('account.status_accepted_short'.tr()), findsOneWidget);
      // A refused request is told on the notifications page, not here.
      expect(find.text('+966 50 444 5566'), findsNothing);
    });

    group('a request that waits', () {
      setUp(() {
        circles.inbox = Success(
          CircleInbox(
            sent: <SentCircleRequest>[
              SentCircleRequest(
                id: 'request-1',
                patientPhoneNumber: '+966507654321',
                circleLabel: 'أمي',
                proposedAppMode: CircleAppMode.simplified,
                status: CircleRequestStatus.pending,
                createdAt: fiveDaysAgo,
              ),
            ],
            received: const <ReceivedCircleRequest>[],
            invitations: const <ReceivedInvitation>[],
          ),
        );
      });

      testWidgets('opens its details', (WidgetTester tester) async {
        await openAccount(tester);
        await openSheet(tester, '+966 50 765 4321');

        expect(find.text('account.request_sheet_title'.tr()), findsOneWidget);
        // In the sheet, and in the row under it.
        expect(find.text('+966 50 765 4321'), findsWidgets);
        expect(find.text('circles.mode_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.cancel_request'.tr()), findsOneWidget);
      });

      testWidgets('is canceled after the sender agrees', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openSheet(tester, '+966 50 765 4321');

        await tester.tap(find.text('circles.cancel_request'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('circles.cancel_confirm_title'.tr()), findsOneWidget);
        expect(
          find.text('circles.cancel_confirm_body_sender'.tr()),
          findsOneWidget,
        );
        await tester.tap(find.text('circles.cancel_confirm_yes'.tr()));
        await tester.pumpAndSettle();

        expect(circles.canceledIds, <String>['request-1']);
        expect(find.text('account.request_sheet_title'.tr()), findsNothing);
        expect(find.text('account.awaiting_title'.tr()), findsNothing);
        expect(find.text('account.request_canceled'.tr()), findsOneWidget);
      });

      testWidgets('stays when the sender says no', (WidgetTester tester) async {
        await openAccount(tester);
        await openSheet(tester, '+966 50 765 4321');

        await tester.tap(find.text('circles.cancel_request'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.cancel_confirm_no'.tr()));
        await tester.pumpAndSettle();

        expect(circles.canceledIds, isEmpty);
        expect(find.text('account.request_sheet_title'.tr()), findsOneWidget);
      });

      testWidgets('stays when the server refuses, and says why', (
        WidgetTester tester,
      ) async {
        circles.canceled = const Error(NetworkFailure());
        await openAccount(tester);
        await openSheet(tester, '+966 50 765 4321');

        await tester.tap(find.text('circles.cancel_request'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.cancel_confirm_yes'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('error.network'.tr()), findsOneWidget);
        expect(find.text('account.request_sheet_title'.tr()), findsOneWidget);
      });
    });

    // One «تعديل» button at the top opens the edit page with the three
    // names: the first name, the last name, then the display name.
    group('changing the names', () {
      Finder nameField(int index) => find.byType(TextField).at(index);

      String fieldText(WidgetTester tester, int index) =>
          tester.widget<TextField>(nameField(index)).controller!.text;

      testWidgets('the edit button opens the edit page with the saved names', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openEdit(tester);

        expect(find.byType(AccountEditScreen), findsOneWidget);
        expect(find.text('account.edit_title'.tr()), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(3));
        expect(fieldText(tester, 0), 'Reem');
        expect(fieldText(tester, 1), 'Alahmadi');
        expect(fieldText(tester, 2), 'Reem');
      });

      testWidgets('the three names are saved and the page shows them', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openEdit(tester);

        await tester.enterText(nameField(0), 'Layla');
        await tester.enterText(nameField(1), 'Salem');
        await tester.enterText(nameField(2), 'Lulu');
        // The account page reads the account again after the save, and the
        // server then answers with the new names.
        circles.account = const Success(
          AccountSummary(
            firstName: 'Layla',
            lastName: 'Salem',
            displayName: 'Lulu',
            phoneNumber: '+966501234567',
          ),
        );
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(onboarding.saved.single, <String>['Layla', 'Salem', 'Lulu']);
        expect(find.byType(AccountEditScreen), findsNothing);
        expect(find.text('Layla Salem'), findsNWidgets(2));
        expect(find.text('Lulu'), findsOneWidget);
      });

      testWidgets('an empty name is marked and nothing is sent', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openEdit(tester);

        await tester.enterText(nameField(2), '');
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(onboarding.saved, isEmpty);
        expect(find.text('circles.field_required'.tr()), findsOneWidget);
        expect(find.byType(AccountEditScreen), findsOneWidget);
      });

      testWidgets('a refusal shows its text and keeps the edit page', (
        WidgetTester tester,
      ) async {
        onboarding.result = const Error(NetworkFailure());
        await openAccount(tester);
        await openEdit(tester);

        await tester.enterText(nameField(2), 'Ree');
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('error.network'.tr()), findsOneWidget);
        expect(find.byType(AccountEditScreen), findsOneWidget);
        expect(fieldText(tester, 2), 'Ree');
      });
    });

    group('signing out and deleting', () {
      Finder inDialog(String text) =>
          find.descendant(of: findAlert(), matching: find.text(text));

      testWidgets('sign out ends the session and opens the sign-in page', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);

        await tester.tap(find.text('auth.sign_out'.tr()));
        await tester.pumpAndSettle();

        expect(auth.signOuts, 1);
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          Routes.auth,
        );
        // The welcome: the first page shows the next dose as on «اليوم»,
        // with the step and its title; «التالي» at the bottom moves on to
        // the second, and «تخطي» is next to it.
        expect(find.text('intro.p1_title'.tr()), findsOneWidget);
        expect(find.text('01 · ${'intro.p1_step'.tr()}'), findsOneWidget);
        expect(find.text('intro.demo.next_dose'.tr()), findsOneWidget);
        expect(find.text('intro.skip'.tr()), findsOneWidget);
        await tester.tap(find.text('intro.next'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('intro.p2_title'.tr()), findsOneWidget);
        expect(find.text('intro.demo.circle'.tr()), findsOneWidget);
      });

      testWidgets(
        'after «تخطي» the welcome does not show again on this phone',
        (WidgetTester tester) async {
          // A new install again for the tests after this one.
          addTearDown(
            () => SharedPreferences.setMockInitialValues(<String, Object>{}),
          );
          await openAccount(tester);
          await tester.tap(find.text('auth.sign_out'.tr()));
          await tester.pumpAndSettle();
          await tester.tap(find.text('intro.skip'.tr()));
          await tester.pumpAndSettle();
          expect(find.text('auth.phone_title'.tr()), findsOneWidget);

          // The next time the sign-in page opens, as after a sign-out.
          AppRouter.router.go(Routes.auth);
          await tester.pumpAndSettle();

          expect(
            AppRouter.router.routeInformationProvider.value.uri.path,
            Routes.authPhone,
          );
          expect(find.text('intro.p1_title'.tr()), findsNothing);
          expect(find.text('auth.phone_title'.tr()), findsOneWidget);
          // The phone page is the first page: no back link to the welcome.
          expect(find.text('common.back'.tr()), findsNothing);
        },
      );

      testWidgets('deleting asks first, and "no" deletes nothing', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);

        await tester.tap(find.text('account.delete_account'.tr()));
        await tester.pumpAndSettle();
        expect(inDialog('account.delete_title'.tr()), findsOneWidget);
        expect(inDialog('account.delete_body'.tr()), findsOneWidget);

        await tester.tap(inDialog('account.cancel'.tr()));
        await tester.pumpAndSettle();

        expect(circles.deletions, isEmpty);
        expect(auth.signOuts, 0);
        expect(findAlert(), findsNothing);
        expect(find.byType(AccountScreen), findsOneWidget);
      });

      testWidgets('"yes" deletes the account and opens the sign-in page', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);

        await tester.tap(find.text('account.delete_account'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(inDialog('account.delete_confirm'.tr()));
        await tester.pumpAndSettle();

        expect(circles.deletions, <AccountDeletion>[const AccountDeletion()]);
        // The tokens are removed from the phone too.
        expect(auth.signOuts, 1);
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          Routes.auth,
        );
      });

      testWidgets('the patient of a circle chooses what happens to it', (
        WidgetTester tester,
      ) async {
        circles.deleted = const Error(PatientChoiceRequiredFailure());
        await openAccount(tester);

        await tester.tap(find.text('account.delete_account'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(inDialog('account.delete_confirm'.tr()));
        await tester.pumpAndSettle();

        expect(inDialog('account.patient_choice_title'.tr()), findsOneWidget);
        expect(auth.signOuts, 0);

        circles.deleted = const Success(null);
        await tester.tap(inDialog('account.patient_choice_keep'.tr()));
        await tester.pumpAndSettle();

        expect(circles.deletions, <AccountDeletion>[
          const AccountDeletion(),
          const AccountDeletion(patientChoice: PatientChoice.keep),
        ]);
        expect(auth.signOuts, 1);
      });

      testWidgets('stopping at the choice deletes nothing', (
        WidgetTester tester,
      ) async {
        circles.deleted = const Error(PatientChoiceRequiredFailure());
        await openAccount(tester);

        await tester.tap(find.text('account.delete_account'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(inDialog('account.delete_confirm'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(inDialog('account.cancel'.tr()));
        await tester.pumpAndSettle();

        // Only the first try reached the server, and it was refused.
        expect(circles.deletions, <AccountDeletion>[const AccountDeletion()]);
        expect(auth.signOuts, 0);
        expect(findAlert(), findsNothing);
      });

      testWidgets('the only manager of a circle agrees to delete it too', (
        WidgetTester tester,
      ) async {
        circles.deleted = const Error(LastManagerFailure());
        await openAccount(tester);

        await tester.tap(find.text('account.delete_account'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(inDialog('account.delete_confirm'.tr()));
        await tester.pumpAndSettle();

        expect(inDialog('account.last_manager_title'.tr()), findsOneWidget);
        expect(inDialog('account.last_manager_body'.tr()), findsOneWidget);

        circles.deleted = const Success(null);
        await tester.tap(inDialog('account.last_manager_confirm'.tr()));
        await tester.pumpAndSettle();

        expect(
          circles.deletions.last,
          const AccountDeletion(deleteLastManagedCircles: true),
        );
        expect(auth.signOuts, 1);
      });

      testWidgets('another failure shows its text and keeps the account', (
        WidgetTester tester,
      ) async {
        circles.deleted = const Error(NetworkFailure());
        await openAccount(tester);

        await tester.tap(find.text('account.delete_account'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(inDialog('account.delete_confirm'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('error.network'.tr()), findsOneWidget);
        expect(auth.signOuts, 0);
        expect(find.byType(AccountScreen), findsOneWidget);
      });
    });
  });

  group('Medical file and emergency card', () {
    /// A tall screen, so that no row needs scrolling in a test.
    void tallPhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> openCircleTab(WidgetTester tester) async {
      tallPhone(tester);
      await pumpApp(tester);
      await tester.tap(inBar('tab.circle'.tr()).first);
      await tester.pumpAndSettle();
      // The router is shared by all tests, so its first frame can still show
      // the page the last test ended on, and that page reads its data once.
      // The Circle tab also reads the medical file for its patient card. The
      // tests count the reads that come after this point.
      circles.medicalFileReads = 0;
      circles.emergencyCardReads = 0;
    }

    Future<void> openFile(WidgetTester tester) async {
      await openCircleTab(tester);
      await tester.tap(find.text('circles.file_title'.tr()));
      await tester.pumpAndSettle();
    }

    Future<void> openEdit(WidgetTester tester) async {
      await openFile(tester);
      await tester.tap(find.text('circles.file_edit'.tr()));
      await tester.pumpAndSettle();
    }

    Future<void> openCard(WidgetTester tester) async {
      await openCircleTab(tester);
      // Taller still: the whole card, the ambulance button and the note are
      // built at once.
      tester.view.physicalSize = const Size(900, 2600);
      await tester.pumpAndSettle();
      await tester.tap(find.text('circles.card_title'.tr()));
      await tester.pumpAndSettle();
    }

    /// The pencil of a contact, named as the page names it.
    Finder pencilOf(String name) =>
        find.byTooltip('circles.contact_edit_action'.tr(args: <String>[name]));

    /// The fields of the contact form: the name, then the number.
    Finder nameField() => find.byType(TextField).first;
    Finder phoneField() => find.byType(TextField).last;

    Future<void> fillNewContact(WidgetTester tester) async {
      await tester.tap(find.text('circles.contact_add'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('medical.relation.wife'.tr()));
      await tester.pumpAndSettle();
      await tester.enterText(nameField(), 'سلمى');
      await tester.enterText(phoneField(), '555555555');
      await tester.pumpAndSettle();
    }

    MedicalFile fileWithContacts(int count) =>
        CirclesFakeRepository.nouraFile.copyWith(
          contacts: <EmergencyContact>[
            for (int i = 0; i < count; i++)
              EmergencyContact(
                id: 'contact-$i',
                name: 'اسم $i',
                relation: 'other',
                phoneNumber: '+96651234567$i',
              ),
          ],
        );

    group('the Circle tab', () {
      testWidgets('shows the selected circle with its two buttons', (
        WidgetTester tester,
      ) async {
        tallPhone(tester);
        await pumpApp(tester);
        await chooseCircle(tester, 'Circle two');

        await tester.tap(inBar('tab.circle'.tr()).first);
        await tester.pumpAndSettle();

        expect(find.byType(CircleTabScreen), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CircleCard),
            matching: find.text('Circle two'),
          ),
          findsOneWidget,
        );
        expect(find.text('circles.file_title'.tr()), findsOneWidget);
        expect(find.text('circles.card_title'.tr()), findsOneWidget);
      });

      testWidgets('a file without medical answers shows the yellow «!»', (
        WidgetTester tester,
      ) async {
        circles.medicalFile = Success(
          CirclesFakeRepository.nouraFile.copyWith(
            profile: const MedicalProfileDraft(),
          ),
        );

        await openCircleTab(tester);
        expect(find.text('medical_alert.tile'.tr()), findsOneWidget);
        expect(find.text('circle_overview.file_hint'.tr()), findsNothing);

        await tester.tap(find.text('circles.file_title'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('medical_alert.title'.tr()), findsOneWidget);
        expect(find.text('medical_alert.fill'.tr()), findsOneWidget);
      });

      testWidgets('a complete file has no «!»', (WidgetTester tester) async {
        await openCircleTab(tester);

        expect(find.text('medical_alert.tile'.tr()), findsNothing);
        expect(find.text('circle_overview.file_hint'.tr()), findsOneWidget);
      });

      testWidgets('shows no card when the account has no circle', (
        WidgetTester tester,
      ) async {
        home.response = Success(homeData(circles: <CareCircleSummary>[]));

        await openCircleTab(tester);

        expect(find.byType(CircleCard), findsNothing);
      });

      testWidgets('shows the managers, the patient and a pending invitation', (
        WidgetTester tester,
      ) async {
        circles.circleOverview = Success(
          CircleOverview(
            name: 'أمي نورة',
            patientName: 'نورة العتيبي',
            patientIsYou: false,
            patientUsesApp: true,
            appMode: 'detailed',
            patientBirthDate: DateTime(1954, 6, 5),
            city: 'بريدة',
            canManage: true,
            members: const <CircleMember>[
              CircleMember(name: 'Reem', isYou: true),
              CircleMember(name: 'نورة', isYou: false, isPatient: true),
            ],
            pendingInvitations: <CirclePendingInvitation>[
              CirclePendingInvitation(
                id: 'invitation-1',
                phoneNumber: '+966559876543',
                createdAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ],
          ),
        );

        await openCircleTab(tester);

        expect(
          find.text(
            '${'circle_overview.managers_two'.tr()} · '
            '${'circle_overview.invitations_one'.tr()}',
          ),
          findsOneWidget,
        );
        expect(find.text('circle_overview.you'.tr()), findsOneWidget);
        expect(find.text('circle_overview.manager'.tr()), findsNWidgets(2));
        expect(find.text('circle_overview.owner'.tr()), findsOneWidget);
        expect(find.text('circle_overview.patient_line'.tr()), findsOneWidget);
        expect(find.text('+966 55 987 6543'), findsOneWidget);
        expect(find.text('circle_overview.resend'.tr()), findsOneWidget);
        expect(find.text('circle_overview.cancel'.tr()), findsOneWidget);
      });

      testWidgets(
        'the circle stays open when its medical file cannot be read',
        (WidgetTester tester) async {
          circles.medicalFile = const Error(ServerFailure());

          await openCircleTab(tester);

          expect(find.byType(CircleCard), findsOneWidget);
          expect(find.text('circles.file_title'.tr()), findsOneWidget);
          expect(find.text('circle_overview.members'.tr()), findsOneWidget);
        },
      );

      testWidgets('«إضافة عضو» opens the invitation sheet', (
        WidgetTester tester,
      ) async {
        await openCircleTab(tester);

        await tester.tap(find.text('circle_overview.add_member'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circle_overview.invite_hint'.tr()), findsOneWidget);
        expect(find.text('circle_overview.send_invite'.tr()), findsOneWidget);
      });
    });

    group('the medical file', () {
      testWidgets('shows the patient, the answers and the contacts', (
        WidgetTester tester,
      ) async {
        await openFile(tester);

        expect(find.byType(MedicalFileScreen), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);
        expect(circles.medicalFileReads, 1);
        expect(find.text('نورة العتيبي'), findsOneWidget);
        expect(find.text('5 ${'circles.months.6'.tr()} 1954'), findsOneWidget);
        expect(find.text(MedicalTexts.bloodTypeLabel('O+')), findsOneWidget);
        expect(find.text('circles.no_allergies'.tr()), findsOneWidget);
        expect(find.text('medical.condition.diabetes'.tr()), findsOneWidget);
        expect(find.text('بريدة'), findsOneWidget);
        expect(find.text('خالد'), findsOneWidget);
        expect(
          find.text(MedicalTexts.phone(CirclesFakeRepository.khaled)),
          findsOneWidget,
        );
        expect(find.text('هدى'), findsOneWidget);
      });

      testWidgets('a part nobody answered reads "غير محدد"', (
        WidgetTester tester,
      ) async {
        circles.medicalFile = Success(
          CirclesFakeRepository.nouraFile.copyWith(
            profile: const MedicalProfileDraft(),
          ),
        );

        await openFile(tester);

        // The blood type, the allergies and the conditions.
        expect(find.text('circles.file_unknown'.tr()), findsNWidgets(3));
      });

      testWidgets(
        'a file that cannot be read says why and can be tried again',
        (WidgetTester tester) async {
          circles.medicalFile = const Error(ServerFailure());
          await openFile(tester);

          expect(find.text('error.server'.tr()), findsOneWidget);
          expect(find.text('circles.file_edit'.tr()), findsNothing);

          circles.medicalFile = Success(CirclesFakeRepository.nouraFile);
          await tester.tap(find.text('auth.retry'.tr()));
          await tester.pumpAndSettle();

          expect(find.text('نورة العتيبي'), findsOneWidget);
          expect(find.text('circles.file_edit'.tr()), findsOneWidget);
        },
      );

      testWidgets('a person who left the circle is refused', (
        WidgetTester tester,
      ) async {
        circles.medicalFile = const Error(ForbiddenFailure());

        await openFile(tester);

        expect(find.text('error.forbidden'.tr()), findsOneWidget);
      });

      testWidgets('back returns to the Circle tab', (
        WidgetTester tester,
      ) async {
        await openFile(tester);

        await tester.tap(find.text('common.back'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(MedicalFileScreen), findsNothing);
        expect(find.byType(AppBottomBar), findsOneWidget);
        expect(find.byType(CircleCard), findsOneWidget);
      });
    });

    group('the emergency contacts', () {
      testWidgets('a contact is added with its relation and number', (
        WidgetTester tester,
      ) async {
        await openFile(tester);
        await fillNewContact(tester);

        await tester.tap(find.text('circles.contact_save'.tr()));
        await tester.pumpAndSettle();

        expect(circles.addedContacts, <ContactDraft>[
          const ContactDraft(
            name: 'سلمى',
            relation: 'wife',
            phoneNumber: '+966555555555',
          ),
        ]);
        expect(find.text('circles.contact_new_title'.tr()), findsNothing);
        expect(find.text('سلمى'), findsOneWidget);
        expect(find.text('+966 55 555 5555'), findsOneWidget);
      });

      testWidgets('a form with nothing filled says what is missing', (
        WidgetTester tester,
      ) async {
        await openFile(tester);
        await tester.tap(find.text('circles.contact_add'.tr()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('circles.contact_save'.tr()));
        await tester.pumpAndSettle();

        // The relation and the name.
        expect(find.text('circles.field_required'.tr()), findsNWidgets(2));
        expect(circles.saveCalls, isEmpty);
      });

      testWidgets('cancel closes the form without saving', (
        WidgetTester tester,
      ) async {
        await openFile(tester);
        await fillNewContact(tester);

        await tester.tap(find.text('circles.contact_cancel'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.contact_new_title'.tr()), findsNothing);
        expect(find.text('circles.contact_add'.tr()), findsOneWidget);
        expect(circles.saveCalls, isEmpty);
      });

      testWidgets('a number that is already a contact says why', (
        WidgetTester tester,
      ) async {
        circles.contactSaved = const Error(DuplicateContactFailure());
        await openFile(tester);
        await fillNewContact(tester);

        await tester.tap(find.text('circles.contact_save'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.duplicate_contact'.tr()), findsOneWidget);
        // The form stays open, with what was typed.
        expect(find.text('circles.contact_new_title'.tr()), findsOneWidget);
        expect(find.widgetWithText(TextField, 'سلمى'), findsOneWidget);
      });

      testWidgets('a contact is changed from its pencil', (
        WidgetTester tester,
      ) async {
        await openFile(tester);

        await tester.tap(pencilOf('خالد'));
        await tester.pumpAndSettle();

        expect(find.text('circles.contact_edit_title'.tr()), findsOneWidget);
        expect(find.widgetWithText(TextField, 'خالد'), findsOneWidget);
        expect(find.widgetWithText(TextField, '51 234 5678'), findsOneWidget);
        // One form is open at a time, so the other contact has no pencil.
        expect(pencilOf('هدى'), findsNothing);

        await tester.enterText(nameField(), 'خالد بن سعد');
        await tester.tap(find.text('circles.contact_save'.tr()));
        await tester.pumpAndSettle();

        expect(circles.changedContacts.single.$1, 'contact-1');
        expect(circles.changedContacts.single.$2.name, 'خالد بن سعد');
        expect(circles.changedContacts.single.$2.phoneNumber, '+966512345678');
        expect(find.text('خالد بن سعد'), findsOneWidget);
        expect(pencilOf('هدى'), findsOneWidget);
      });

      testWidgets('a contact is removed only after the person says yes', (
        WidgetTester tester,
      ) async {
        await openFile(tester);
        await tester.tap(pencilOf('هدى'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('circles.contact_delete'.tr()));
        await tester.pumpAndSettle();

        expect(findAlert(), findsOneWidget);
        expect(
          find.text('circles.contact_delete_body'.tr(args: <String>['هدى'])),
          findsOneWidget,
        );

        await tester.tap(find.text('circles.contact_delete_no'.tr()));
        await tester.pumpAndSettle();
        expect(findAlert(), findsNothing);
        expect(circles.deletedContactIds, isEmpty);

        await tester.tap(find.text('circles.contact_delete'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.contact_delete_yes'.tr()));
        await tester.pumpAndSettle();

        expect(circles.deletedContactIds, <String>['contact-2']);
        expect(find.text('هدى'), findsNothing);
        expect(find.text('خالد'), findsOneWidget);
      });

      testWidgets('with no contacts the page says where they are used', (
        WidgetTester tester,
      ) async {
        circles.medicalFile = Success(fileWithContacts(0));

        await openFile(tester);

        expect(find.text('circles.file_contacts_empty'.tr()), findsOneWidget);
        expect(find.text('circles.contact_add'.tr()), findsOneWidget);
      });

      testWidgets('with five contacts the add button gives way to a note', (
        WidgetTester tester,
      ) async {
        circles.medicalFile = Success(fileWithContacts(5));

        await openFile(tester);

        expect(find.text('circles.contact_add'.tr()), findsNothing);
        expect(find.text('circles.contact_max'.tr()), findsOneWidget);
      });
    });

    group('the edit page', () {
      testWidgets('starts from the saved values', (WidgetTester tester) async {
        await openEdit(tester);

        expect(find.byType(MedicalFileEditScreen), findsOneWidget);
        expect(find.text('circles.file_edit_title'.tr()), findsOneWidget);
        expect(find.widgetWithText(TextField, 'نورة'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'العتيبي'), findsOneWidget);
        expect(find.text('بريدة'), findsOneWidget);
        final FilterChip bloodType = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, MedicalTexts.bloodTypeLabel('O+')),
        );
        expect(bloodType.selected, isTrue);
      });

      testWidgets('saving a new blood type sends only the health answers', (
        WidgetTester tester,
      ) async {
        await openEdit(tester);
        final int readsBeforeSave = circles.medicalFileReads;

        await tester.tap(
          find.widgetWithText(FilterChip, MedicalTexts.bloodTypeLabel('A+')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.file_save'.tr()));
        await tester.pumpAndSettle();

        expect(circles.saveCalls, <String>['profile']);
        expect(circles.profileUpdates.single.bloodType, 'A+');
        // «حفظ» goes back to the circle tab, past the medical file page,
        // with the confirmation. Its patient card has the new blood type at
        // once: what the server kept comes back from the save, so nothing is
        // read again. The edit page started from the file page's file, so it
        // read nothing either.
        expect(find.byType(MedicalFileEditScreen), findsNothing);
        expect(find.byType(MedicalFileScreen), findsNothing);
        expect(find.byType(CircleTabScreen), findsOneWidget);
        expect(find.text('circles.file_saved'.tr()), findsOneWidget);
        expect(
          find.textContaining(MedicalTexts.bloodTypeLabel('A+')),
          findsOneWidget,
        );
        expect(
          find.textContaining(MedicalTexts.bloodTypeLabel('O+')),
          findsNothing,
        );
        expect(circles.medicalFileReads, readsBeforeSave);
      });

      testWidgets('saving without a change closes the page without a call', (
        WidgetTester tester,
      ) async {
        await openEdit(tester);

        await tester.tap(find.text('circles.file_save'.tr()));
        await tester.pumpAndSettle();

        expect(circles.saveCalls, isEmpty);
        expect(find.byType(MedicalFileEditScreen), findsNothing);
        expect(find.byType(CircleTabScreen), findsOneWidget);
      });

      testWidgets('the names of a patient with an account are not editable', (
        WidgetTester tester,
      ) async {
        circles.medicalFile = Success(CirclesFakeRepository.nouraWithAccount);

        await openEdit(tester);

        expect(find.text('circles.file_name_note'.tr()), findsOneWidget);
        expect(find.text('نورة العتيبي'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'نورة'), findsNothing);
      });

      testWidgets('"other" without its text is not saved', (
        WidgetTester tester,
      ) async {
        await openEdit(tester);

        await tester.tap(find.text('medical.condition.other'.tr()).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.file_save'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.field_required'.tr()), findsOneWidget);
        expect(circles.saveCalls, isEmpty);
        expect(find.byType(MedicalFileEditScreen), findsOneWidget);

        // The field that "other" opened is the last one on the page.
        await tester.enterText(find.byType(TextField).last, 'نقرس');
        await tester.tap(find.text('circles.file_save'.tr()));
        await tester.pumpAndSettle();

        expect(circles.profileUpdates.single.conditions?.other, 'نقرس');
        expect(find.byType(MedicalFileEditScreen), findsNothing);
      });

      testWidgets('a refused save stays on the page and says why', (
        WidgetTester tester,
      ) async {
        circles.profileSaved = const Error(ServerFailure());
        await openEdit(tester);

        await tester.tap(
          find.widgetWithText(FilterChip, MedicalTexts.bloodTypeLabel('A+')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.file_save'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(MedicalFileEditScreen), findsOneWidget);
        expect(find.text('error.server'.tr()), findsOneWidget);
        expect(find.text('circles.file_saved'.tr()), findsNothing);
      });
    });

    group('the emergency card', () {
      testWidgets('shows the name, the blood type and the people to call', (
        WidgetTester tester,
      ) async {
        await openCard(tester);

        expect(find.byType(EmergencyCardScreen), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);
        expect(circles.emergencyCardReads, 1);
        expect(find.text('emergency_card.read_only'.tr()), findsOneWidget);
        expect(find.text('نورة العتيبي'), findsOneWidget);
        expect(find.text('O+'), findsOneWidget);
        expect(find.text('emergency_card.no_allergies'.tr()), findsOneWidget);
        expect(find.text('medical.condition.diabetes'.tr()), findsOneWidget);
        expect(
          find.text('خالد · ${'medical.relation.son'.tr()}'),
          findsOneWidget,
        );
        expect(
          find.text(MedicalTexts.phone(CirclesFakeRepository.khaled)),
          findsOneWidget,
        );
        expect(
          find.text('هدى · ${'medical.relation.daughter'.tr()}'),
          findsOneWidget,
        );
        // The ambulance button sits under the card.
        expect(find.text('emergency_card.ambulance'.tr()), findsOneWidget);
      });

      testWidgets('«English» switches the card and keeps the typed names', (
        WidgetTester tester,
      ) async {
        await openCard(tester);

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        expect(find.text('card_en.read_only'.tr()), findsOneWidget);
        expect(find.text('card_en.condition.diabetes'.tr()), findsOneWidget);
        expect(find.text('نورة العتيبي'), findsOneWidget);

        await tester.tap(find.text('emergency_card.lang_ar'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('emergency_card.read_only'.tr()), findsOneWidget);
      });

      testWidgets('a card with nothing answered still opens', (
        WidgetTester tester,
      ) async {
        circles.emergencyCard = Success(
          EmergencyCard(
            firstName: 'نورة',
            lastName: 'العتيبي',
            profile: const MedicalProfileDraft(),
            contacts: const <EmergencyContact>[],
          ),
        );

        await openCard(tester);

        expect(find.text('—'), findsOneWidget);
        // The allergies and the conditions.
        expect(find.text('emergency_card.unknown'.tr()), findsNWidgets(2));
        expect(find.text('emergency_card.no_contacts'.tr()), findsOneWidget);
      });

      testWidgets('a person who left the circle is refused and can try again', (
        WidgetTester tester,
      ) async {
        circles.emergencyCard = const Error(ForbiddenFailure());
        await openCard(tester);

        expect(find.text('error.forbidden'.tr()), findsOneWidget);

        circles.emergencyCard = Success(CirclesFakeRepository.nouraCard);
        await tester.tap(find.text('auth.retry'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('نورة العتيبي'), findsOneWidget);
      });

      testWidgets('back returns to the Circle tab', (
        WidgetTester tester,
      ) async {
        await openCard(tester);

        await tester.tap(find.text('common.back'.tr()));
        await tester.pumpAndSettle();

        expect(find.byType(EmergencyCardScreen), findsNothing);
        expect(find.byType(AppBottomBar), findsOneWidget);
      });

      testWidgets('reads the card again at each visit', (
        WidgetTester tester,
      ) async {
        await openCard(tester);
        await tester.tap(find.text('common.back'.tr()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('circles.card_title'.tr()));
        await tester.pumpAndSettle();

        expect(circles.emergencyCardReads, 2);
      });
    });
  });
}
