import 'package:app/core/errors/failure.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/presentation/pages/circle_tab_screen.dart';
import 'package:app/features/circles/presentation/pages/emergency_card_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_screen.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/shell/widgets/app_bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/app_shell_harness.dart';
import '../support/circles_fakes.dart';
import '../support/home_fakes.dart';

void main() {
  setUpShellApp();

  group('Medical file and emergency card', () {
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

      testWidgets('shows the members, the patient and a pending invitation', (
        WidgetTester tester,
      ) async {
        circles.circleOverview = Success(
          CircleOverview(
            name: 'أمي نورة',
            patientName: 'نورة العتيبي',
            patientIsYou: false,
            patientUsesApp: true,
            appMode: CircleAppMode.detailed,
            patientBirthDate: DateTime(1954, 6, 5),
            city: 'بريدة',
            canManage: true,
            members: const <CircleMember>[
              CircleMember(name: 'Reem', isYou: true, isLeader: true),
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

        // The header counts every member (Reem and Noura), not only the
        // managers.
        expect(
          find.text(
            '${'circle_overview.members_count_two'.tr()} · '
            '${'circle_overview.invitations_one'.tr()}',
          ),
          findsOneWidget,
        );
        expect(find.text('circle_overview.you'.tr()), findsOneWidget);
        expect(find.text('circle_overview.leader'.tr()), findsOneWidget);
        expect(find.text('circle_overview.owner'.tr()), findsOneWidget);
        expect(find.text('circle_overview.patient_line'.tr()), findsOneWidget);
        expect(find.text('+966 55 987 6543'), findsOneWidget);
        expect(find.text('circle_overview.resend'.tr()), findsOneWidget);
        expect(find.text('common.cancel'.tr()), findsOneWidget);
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
        expect(find.text('common.field_required'.tr()), findsNWidgets(2));
        expect(circles.saveCalls, isEmpty);
      });

      testWidgets('cancel closes the form without saving', (
        WidgetTester tester,
      ) async {
        await openFile(tester);
        await fillNewContact(tester);

        await tester.tap(find.text('common.cancel'.tr()));
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

        expect(find.text('common.field_required'.tr()), findsOneWidget);
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
        expect(
          find.text('emergency_card.ambulance'.tr(args: <String>['997'])),
          findsOneWidget,
        );
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
