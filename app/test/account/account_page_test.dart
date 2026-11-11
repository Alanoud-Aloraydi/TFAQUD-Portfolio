import 'package:app/core/errors/failure.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_shell_harness.dart';
import '../support/circles_fakes.dart';

void main() {
  setUpShellApp();

  group('Account page', () {
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

    // Noon five days ago on the patient's (Riyadh's) calendar. The page
    // counts calendar days there, on the real clock: «now minus 5 days» read
    // six days between 00:00 and 01:00 in Riyadh.
    final PatientClock riyadh = PatientClock(defaultPatientZone);
    final DateTime today = riyadh.today();
    final DateTime fiveDaysAgo = riyadh.momentOf(
      DateTime.utc(today.year, today.month, today.day - 5),
      '12:00',
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
              proposedAppMode: CircleAppMode.simplified,
              status: CircleRequestStatus.pending,
              createdAt: fiveDaysAgo,
            ),
            const SentCircleRequest(
              id: 'request-2',
              patientPhoneNumber: '+966501112233',
              proposedAppMode: CircleAppMode.detailed,
              status: CircleRequestStatus.accepted,
            ),
            const SentCircleRequest(
              id: 'request-3',
              patientPhoneNumber: '+966504445566',
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
        expect(find.text('common.field_required'.tr()), findsOneWidget);
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
}
