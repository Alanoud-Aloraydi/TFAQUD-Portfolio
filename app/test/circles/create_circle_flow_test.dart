import 'package:app/core/errors/failure.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/pages/patient_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/request_patient_screen.dart';
import 'package:app/features/circles/presentation/pages/self_circle_basics_screen.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/app_shell_harness.dart';
import '../support/circles_fakes.dart';
import '../support/home_fakes.dart';

void main() {
  setUpShellApp();

  group('Circle creation for your own care', () {
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
      // The top bar's «+» has the same words, so tap the button itself.
      await tester.tap(
        find.widgetWithText(FilledButton, 'home.create_circle'.tr()),
      );
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
      // The account's own: its city also gives the patient's zone.
      expect(request.birthDate, DateTime(1990, 3, 4));
      expect(request.city, 'الرياض');
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
      expect(find.text('common.field_required'.tr()), findsNWidgets(2));
      expect(find.text('circles.self_title'.tr()), findsOneWidget);
      expect(circles.requests, isEmpty);
    });

    testWidgets('an account that cannot be read offers a retry', (
      WidgetTester tester,
    ) async {
      circles.account = const Error(NetworkFailure());
      await openFirstStep(tester);

      expect(find.text('circles.account_failed'.tr()), findsOneWidget);
      // The page still works: it asks for the birth date and the city.
      expect(find.text('circles.birth_date'.tr()), findsOneWidget);

      circles.account = const Success(CirclesFakeRepository.reem);
      await tester.tap(find.text('auth.retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('circles.account_failed'.tr()), findsNothing);
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
      expect(find.text('common.field_required'.tr()), findsOneWidget);
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
        expect(find.text('common.field_required'.tr()), findsNWidgets(4));
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
        expect(created.patientFirstName, 'نورة');
        expect(created.patientLastName, 'العتيبي');
        expect(created.birthDate, DateTime(1954, 6, 5));
        expect(created.city, 'بريدة');
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
}
