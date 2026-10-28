import 'dart:convert';
import 'dart:io';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
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
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
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
  /// How many times the phone was signed out.
  int signOuts = 0;

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

/// The start page builds an OnboardingCubit from the OnboardingUseCase, and the
/// account page saves the names through it. It keeps what it was asked to save.
class _OfflineOnboardingRepository implements OnboardingRepositoryDomain {
  /// The names that were saved, in order: first name, last name, display name.
  final List<List<String>> saved = <List<String>>[];
  Result<bool, Failure> result = const Success(true);

  @override
  Future<Result<bool, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    saved.add(<String>[firstName, lastName, displayName]);
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
  final circles = CirclesFakeRepository();
  final auth = _OfflineAuthRepository();
  final onboarding = _OfflineOnboardingRepository();

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
    testWidgets('shows the top bar actions, four tabs and the add button', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.byTooltip('topbar.account'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.notifications'.tr()), findsOneWidget);
      expect(find.byTooltip('topbar.add_circle'.tr()), findsOneWidget);
      expect(find.byTooltip('tab.add'.tr()), findsOneWidget);
      expect(tester.widget<GlassAddButton>(find.byType(GlassAddButton)).onPressed, isNull);
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

    testWidgets('every tab keeps both bars and selection', (
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

    testWidgets('an admin opens the add sheet', (
      WidgetTester tester,
    ) async {
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

      await tester.tap(find.byTooltip('tab.add'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('add.title'.tr()), findsOneWidget);

      await tester.tap(find.text('add.medication'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('medications.add_title'.tr()), findsOneWidget);
      final save = find.text('medications.save'.tr());
      await tester.dragUntilVisible(
        save,
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
      expect(find.text('medications.field_required'.tr()), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField).first).focusNode!.hasFocus, isTrue);
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
      final IconButton addCircle = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'topbar.add_circle'.tr(),
        ),
      );
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
      'account opens a standalone page and back returns to the shell',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await tester.tap(find.byTooltip('topbar.account'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.text('account.title'.tr()), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);

        await tester.tap(find.text('common.back'.tr()));
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
      await tester.tap(find.byTooltip('topbar.add_circle'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('onboarding.self_title'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.continue'.tr()));
      await tester.pumpAndSettle();
      return tester
          .element(find.byType(SelfCircleBasicsScreen))
          .read<CreateCircleCubit>();
    }

    /// Fills what the date picker and the city sheet would fill, then goes to
    /// the second step.
    Future<void> finishFirstStep(
      WidgetTester tester,
      CreateCircleCubit cubit,
    ) async {
      cubit.birthDateChanged(DateTime(1964, 3, 12));
      cubit.cityChanged('الرياض');
      await tester.pump();
      await tester.tap(find.text('circles.next'.tr()));
      await tester.pumpAndSettle();
    }

    testWidgets('the "+" opens the start page with a back link and no skip', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('topbar.add_circle'.tr()));
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

    testWidgets('the first step shows the account name and asks for the rest', (
      WidgetTester tester,
    ) async {
      await openFirstStep(tester);

      expect(find.text('circles.self_title'.tr()), findsOneWidget);
      expect(find.text('Reem Alahmadi'), findsOneWidget);

      await tester.tap(find.text('circles.next'.tr()));
      await tester.pumpAndSettle();
      // The birth date and the city are missing; the step stays.
      expect(find.text('circles.field_required'.tr()), findsNWidgets(2));
      expect(find.text('circles.self_title'.tr()), findsOneWidget);
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
      await tester.tap(find.text('circles.next'.tr()));
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

        // The lists open about 40 years back, on the first of January.
        await tester.tap(find.text('circles.months.3'.tr()));
        await tester.pump();
        await tester.tap(find.text('circles.date_confirm'.tr()));
        await tester.pumpAndSettle();

        final int year = DateTime.now().year - 40;
        expect(cubit.state.birthDate, DateTime(year, 3, 1));
        expect(find.text('1 ${'circles.months.3'.tr()} $year'), findsOneWidget);
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
      // Nothing to fill in: no form and no next button.
      expect(find.text('circles.birth_date'.tr()), findsNothing);
      expect(find.text('circles.next'.tr()), findsNothing);

      await tester.tap(find.text('circles.back_home'.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('three steps create the circle and open the home page', (
      WidgetTester tester,
    ) async {
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await finishFirstStep(tester, cubit);

      // Step 2: blood type and a condition.
      expect(find.text('circles.health_hint'.tr()), findsOneWidget);
      await tester.tap(find.text('\u200EO+\u200E'));
      await tester.tap(find.text('medical.condition.diabetes'.tr()));
      await tester.pump();
      await tester.tap(find.text('circles.next'.tr()));
      await tester.pumpAndSettle();

      // Step 3: an allergy, then the circle is created.
      expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);
      await tester.tap(find.text('medical.medication.penicillin'.tr()));
      await tester.pump();
      await tester.tap(find.text('circles.create'.tr()));
      await tester.pumpAndSettle();

      final request = circles.requests.single;
      expect(request.name, 'circles.preset.care'.tr());
      expect(request.birthDate, DateTime(1964, 3, 12));
      expect(request.city, 'الرياض');
      expect(
        request.medicalProfile,
        const MedicalProfileDraft(
          bloodType: 'O+',
          conditions: ConditionsDraft.listed(codes: <String>['diabetes']),
          allergies: AllergiesDraft.listed(medication: <String>['penicillin']),
        ),
      );
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('skipping the two health steps sends no medical profile', (
      WidgetTester tester,
    ) async {
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await finishFirstStep(tester, cubit);

      await tester.tap(find.text('circles.skip'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);

      await tester.tap(find.text('circles.skip'.tr()));
      await tester.pumpAndSettle();

      expect(circles.requests.single.medicalProfile, isNull);
      expect(find.byType(AppBottomBar), findsOneWidget);
    });

    testWidgets('"other" in the health step asks for its text', (
      WidgetTester tester,
    ) async {
      final CreateCircleCubit cubit = await openFirstStep(tester);
      await finishFirstStep(tester, cubit);

      await tester.tap(find.text('medical.condition.other'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.other_hint'.tr()), findsOneWidget);

      await tester.tap(find.text('circles.next'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.field_required'.tr()), findsOneWidget);
      expect(find.text('circles.health_hint'.tr()), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Gout');
      await tester.pump();
      await tester.tap(find.text('circles.next'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);
    });

    testWidgets(
      'a refusal shows its text and keeps the user on the last step',
      (WidgetTester tester) async {
        circles.created = const Error(AlreadyHasCircleFailure());
        final CreateCircleCubit cubit = await openFirstStep(tester);
        await finishFirstStep(tester, cubit);
        await tester.tap(find.text('circles.skip'.tr()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.already_has_circle'.tr()), findsOneWidget);
        expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);
        expect(find.byType(AppBottomBar), findsNothing);
      },
    );
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
      await tester.tap(find.byTooltip('topbar.add_circle'.tr()));
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
        await tester.tap(find.byTooltip('topbar.add_circle'.tr()));
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
        // The label chips, the mode and the note about the patient's consent.
        expect(find.text('circles.label.mother'.tr()), findsOneWidget);
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
          expect(request.circleLabel, 'circles.label.mother'.tr());
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

      testWidgets('a label of your own asks for the typed word', (
        WidgetTester tester,
      ) async {
        await openFlow(tester, patientUsesApp: true);
        await tester.tap(find.text('circles.label.other'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('circles.custom_label'.tr()), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, '501234567');
        await tester.pump();
        await tester.tap(find.text('circles.send_request'.tr()));
        await tester.pumpAndSettle();
        expect(circles.sentRequests, isEmpty);
        expect(find.text('circles.field_required'.tr()), findsOneWidget);
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
        await tester.tap(find.text('circles.next'.tr()));
        await tester.pumpAndSettle();

        // The two names, the birth date and the city.
        expect(find.text('circles.field_required'.tr()), findsNWidgets(4));
        expect(find.text('circles.patient_title'.tr()), findsOneWidget);
      });

      testWidgets(
        'shows how the circle will be named while the name is typed',
        (WidgetTester tester) async {
          await openPatientBasics(tester);
          expect(
            find.text(
              'circles.label_hint'.tr(
                args: <String>['circles.label.mother'.tr()],
              ),
            ),
            findsOneWidget,
          );

          await tester.enterText(find.byType(TextField).first, 'نورة');
          await tester.pump();
          final String name = '${'circles.label.mother'.tr()} نورة';
          expect(
            find.text('circles.name_preview'.tr(args: <String>[name])),
            findsOneWidget,
          );

          await tester.tap(find.text('circles.label.grandmother'.tr()));
          await tester.pump();
          final String other = '${'circles.label.grandmother'.tr()} نورة';
          expect(
            find.text('circles.name_preview'.tr(args: <String>[other])),
            findsOneWidget,
          );
        },
      );

      testWidgets('a label of your own asks for the typed word', (
        WidgetTester tester,
      ) async {
        final CreateCircleCubit cubit = await openPatientBasics(tester);
        await tester.tap(find.text('circles.label.other'.tr()));
        await tester.pumpAndSettle();
        expect(find.text('circles.custom_label'.tr()), findsOneWidget);

        await tester.enterText(find.byType(TextField).at(0), 'نورة');
        await tester.enterText(find.byType(TextField).at(1), 'العتيبي');
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();
        await tester.tap(find.text('circles.next'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.field_required'.tr()), findsOneWidget);
        expect(find.text('circles.patient_title'.tr()), findsOneWidget);
      });

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

      testWidgets('three steps create the circle and open the home page', (
        WidgetTester tester,
      ) async {
        final CreateCircleCubit cubit = await openPatientBasics(tester);
        await tester.enterText(find.byType(TextField).at(0), 'نورة');
        await tester.enterText(find.byType(TextField).at(1), 'العتيبي');
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();
        await tester.tap(find.text('circles.next'.tr()));
        await tester.pumpAndSettle();

        // Step 2: the same page as for your own circle.
        expect(find.text('circles.health_hint'.tr()), findsOneWidget);
        await tester.tap(find.text('\u200EO+\u200E'));
        await tester.pump();
        await tester.tap(find.text('circles.next'.tr()));
        await tester.pumpAndSettle();

        // Step 3: the circle is created.
        expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);
        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        final created = circles.patientCircles.single;
        expect(created.name, '${'circles.label.mother'.tr()} نورة');
        expect(created.patientFirstName, 'نورة');
        expect(created.patientLastName, 'العتيبي');
        expect(created.birthDate, DateTime(1954, 6, 5));
        expect(created.city, 'بريدة');
        expect(
          created.medicalProfile,
          const MedicalProfileDraft(bloodType: 'O+'),
        );
        expect(circles.requests, isEmpty);
        expect(find.byType(AppBottomBar), findsOneWidget);
      });

      testWidgets(
        'a refusal shows its text and keeps the user on the last step',
        (WidgetTester tester) async {
          circles.createdPatient = const Error(ModeConflictFailure());
          final CreateCircleCubit cubit = await openPatientBasics(tester);
          await tester.enterText(find.byType(TextField).at(0), 'نورة');
          await tester.enterText(find.byType(TextField).at(1), 'العتيبي');
          cubit.birthDateChanged(DateTime(1954, 6, 5));
          cubit.cityChanged('بريدة');
          await tester.pump();
          await tester.tap(find.text('circles.next'.tr()));
          await tester.pumpAndSettle();
          await tester.tap(find.text('circles.skip'.tr()));
          await tester.pumpAndSettle();

          await tester.tap(find.text('circles.create'.tr()));
          await tester.pumpAndSettle();

          expect(find.text('circles.mode_conflict'.tr()), findsOneWidget);
          expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);
          expect(find.byType(AppBottomBar), findsNothing);
        },
      );
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
      expect(
        find.text('circles.declined_body'.tr(args: <String>['أمي'])),
        findsOneWidget,
      );
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
        expect(find.text('أمي نورة'), findsOneWidget);
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
        // The name of the circle was set by the sender; the name is the account's.
        expect(find.text('أمي نورة'), findsOneWidget);
        expect(find.text('circles.set_by_requester'.tr()), findsOneWidget);
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
            'circles.complete_card_body'.tr(
              args: <String>['سارة الحربي', 'أمي نورة'],
            ),
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
        expect(find.text('أمي نورة'), findsOneWidget);
      });

      testWidgets('three steps create the circle from the request', (
        WidgetTester tester,
      ) async {
        circles.inbox = Success(agreed);
        await openNotifications(tester, 1);
        await tester.tap(find.text('common.continue'.tr()));
        await tester.pumpAndSettle();

        // The date and the city sheets are covered by the first flow's tests.
        final CreateCircleCubit cubit = tester
            .element(find.byType(ApprovedCircleBasicsScreen))
            .read<CreateCircleCubit>();
        cubit.birthDateChanged(DateTime(1954, 6, 5));
        cubit.cityChanged('بريدة');
        await tester.pump();
        await tester.tap(find.text('circles.next'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.health_hint'.tr()), findsOneWidget);
        await tester.tap(find.text('‎O+‎'));
        await tester.pump();
        await tester.tap(find.text('circles.next'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('circles.allergies_hint'.tr()), findsOneWidget);
        await tester.tap(find.text('medical.medication.penicillin'.tr()));
        await tester.pump();
        await tester.tap(find.text('circles.create'.tr()));
        await tester.pumpAndSettle();

        expect(circles.completedIds, <String>['request-in-1']);
        final completion = circles.completions.single;
        expect(completion.birthDate, DateTime(1954, 6, 5));
        expect(completion.city, 'بريدة');
        expect(
          completion.medicalProfile,
          const MedicalProfileDraft(
            bloodType: 'O+',
            allergies: AllergiesDraft.listed(
              medication: <String>['penicillin'],
            ),
          ),
        );
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

      for (final String route in <String>[
        Routes.completeRequest,
        Routes.completeRequestHealth,
        Routes.completeRequestAllergies,
      ]) {
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
      expect(find.text('+966 50 123 4567'), findsOneWidget);
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
      expect(find.text('أمي'), findsOneWidget);
      expect(find.text('أبي'), findsOneWidget);
      // The number of days is written 0-9.
      expect(
        find.text('account.sent_days_few'.tr(args: <String>['5'])),
        findsOneWidget,
      );
      expect(find.text('circles.request_status_pending'.tr()), findsOneWidget);
      expect(find.text('account.status_accepted_short'.tr()), findsOneWidget);
      // A refused request is told on the notifications page, not here.
      expect(find.text('خالتي'), findsNothing);
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
        await openSheet(tester, 'أمي');

        expect(find.text('account.request_sheet_title'.tr()), findsOneWidget);
        expect(find.text('+966 50 765 4321'), findsOneWidget);
        expect(find.text('circles.mode_simplified'.tr()), findsOneWidget);
        expect(find.text('circles.cancel_request'.tr()), findsOneWidget);
      });

      testWidgets('is canceled after the sender agrees', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openSheet(tester, 'أمي');

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
        await openSheet(tester, 'أمي');

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
        await openSheet(tester, 'أمي');

        await tester.tap(find.text('circles.cancel_request'.tr()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('circles.cancel_confirm_yes'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('error.network'.tr()), findsOneWidget);
        expect(find.text('account.request_sheet_title'.tr()), findsOneWidget);
      });
    });

    group('changing the names', () {
      testWidgets('the display name is saved with the other two names', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openSheet(tester, 'account.display_name'.tr());

        expect(find.text('account.edit_display_title'.tr()), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Ree');
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(onboarding.saved.single, <String>['Reem', 'Alahmadi', 'Ree']);
        expect(find.text('account.edit_display_title'.tr()), findsNothing);
        expect(find.text('Ree'), findsOneWidget);
        expect(find.text('account.saved'.tr()), findsOneWidget);
      });

      testWidgets('the full name is saved with the display name', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openSheet(tester, 'account.full_name'.tr());

        expect(find.text('account.edit_full_title'.tr()), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2));
        await tester.enterText(find.byType(TextField).at(0), 'Layla');
        await tester.enterText(find.byType(TextField).at(1), 'Salem');
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(onboarding.saved.single, <String>['Layla', 'Salem', 'Reem']);
        expect(find.text('Layla Salem'), findsNWidgets(2));
      });

      testWidgets('an empty name is marked and nothing is sent', (
        WidgetTester tester,
      ) async {
        await openAccount(tester);
        await openSheet(tester, 'account.display_name'.tr());

        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(onboarding.saved, isEmpty);
        expect(find.text('circles.field_required'.tr()), findsOneWidget);
        expect(find.text('account.edit_display_title'.tr()), findsOneWidget);
      });

      testWidgets('a refusal shows its text and keeps the sheet', (
        WidgetTester tester,
      ) async {
        onboarding.result = const Error(NetworkFailure());
        await openAccount(tester);
        await openSheet(tester, 'account.display_name'.tr());

        await tester.enterText(find.byType(TextField), 'Ree');
        await tester.tap(find.text('account.save'.tr()));
        await tester.pumpAndSettle();

        expect(find.text('error.network'.tr()), findsOneWidget);
        expect(find.text('account.edit_display_title'.tr()), findsOneWidget);
        // The page still shows the old name.
        expect(find.text('Reem'), findsOneWidget);
      });
    });

    group('signing out and deleting', () {
      Finder inDialog(String text) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(text),
      );

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
      });

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
        expect(find.byType(AlertDialog), findsNothing);
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
        expect(find.byType(AlertDialog), findsNothing);
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
      // The router is shared by all tests, so its first frame can still show
      // the page the last test ended on, and that page reads its data once.
      // The tests count the reads that come after this point.
      circles.medicalFileReads = 0;
      circles.emergencyCardReads = 0;
      await tester.tap(inBar('tab.circle'.tr()).first);
      await tester.pumpAndSettle();
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
        await tester.tap(find.widgetWithText(ChoiceChip, 'Circle two'));
        await tester.pumpAndSettle();

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

      testWidgets('shows no card when the account has no circle', (
        WidgetTester tester,
      ) async {
        home.response = Success(homeData(circles: <CareCircleSummary>[]));

        await openCircleTab(tester);

        expect(find.byType(CircleCard), findsNothing);
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

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text('circles.contact_delete_body'.tr(args: <String>['هدى'])),
          findsOneWidget,
        );

        await tester.tap(find.text('circles.contact_delete_no'.tr()));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
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
        // Back on the file page, with the confirmation. The file page reads
        // the file once more after the save, to show what the server kept.
        expect(find.byType(MedicalFileEditScreen), findsNothing);
        expect(find.byType(MedicalFileScreen), findsOneWidget);
        expect(find.text('circles.file_saved'.tr()), findsOneWidget);
        expect(circles.medicalFileReads, readsBeforeSave + 1);
      });

      testWidgets('saving without a change closes the page without a call', (
        WidgetTester tester,
      ) async {
        await openEdit(tester);

        await tester.tap(find.text('circles.file_save'.tr()));
        await tester.pumpAndSettle();

        expect(circles.saveCalls, isEmpty);
        expect(find.byType(MedicalFileEditScreen), findsNothing);
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
        expect(find.text('circles.card_read_only'.tr()), findsOneWidget);
        expect(find.text('نورة العتيبي'), findsOneWidget);
        expect(find.text('O+'), findsOneWidget);
        expect(find.text('circles.no_allergies'.tr()), findsOneWidget);
        expect(find.text('medical.condition.diabetes'.tr()), findsOneWidget);
        expect(
          find.text('خالد (${'medical.relation.son'.tr()})'),
          findsOneWidget,
        );
        expect(
          find.text(MedicalTexts.phone(CirclesFakeRepository.khaled)),
          findsOneWidget,
        );
        expect(
          find.text('هدى (${'medical.relation.daughter'.tr()})'),
          findsOneWidget,
        );
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
        expect(find.text('circles.file_unknown'.tr()), findsNWidgets(2));
        expect(find.text('circles.card_no_contacts'.tr()), findsOneWidget);
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
