import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';

/// The file of Noura with [count] contacts.
MedicalFile _fileWithContacts(int count) =>
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

void main() {
  late CirclesFakeRepository circles;
  late MedicalFileCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    cubit = MedicalFileCubit(CirclesUseCase(circles), 'circle-1');
  });

  tearDown(() => cubit.close());

  /// Opens the form for a new contact and fills it.
  void fillNewContact({
    String relation = 'wife',
    String name = 'سلمى',
    String phone = '555555555',
  }) {
    cubit.startAdd();
    cubit.relationChosen(relation);
    cubit.nameChanged(name);
    cubit.phoneChanged(phone);
  }

  /// Lets a read that the cubit started without waiting for finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('reading the file', () {
    test('starts in the loading state', () {
      expect(cubit.state.status, MedicalFileStatus.loading);
      expect(cubit.state.file, isNull);
    });

    test('shows the file once it is read', () async {
      await cubit.load();

      expect(cubit.state.status, MedicalFileStatus.ready);
      expect(cubit.state.file, CirclesFakeRepository.nouraFile);
      expect(circles.medicalFileReads, 1);
    });

    test('a failed first read says why, and can be tried again', () async {
      circles.medicalFile = const Error(ServerFailure());
      await cubit.load();

      expect(cubit.state.status, MedicalFileStatus.failure);
      expect(cubit.state.messageKey, 'error.server');
      expect(cubit.state.file, isNull);
      expect(cubit.state.sessionEnded, isFalse);

      circles.medicalFile = Success(CirclesFakeRepository.nouraFile);
      await cubit.load();

      expect(cubit.state.status, MedicalFileStatus.ready);
      expect(cubit.state.messageKey, isNull);
    });

    test('an ended sign-in is told to the page', () async {
      circles.medicalFile = const Error(UnauthorizedFailure());
      await cubit.load();

      expect(cubit.state.status, MedicalFileStatus.failure);
      expect(cubit.state.sessionEnded, isTrue);
    });

    test('a failed second read keeps the page and the file', () async {
      await cubit.load();
      circles.medicalFile = const Error(ServerFailure());

      await cubit.load();

      expect(cubit.state.status, MedicalFileStatus.ready);
      expect(cubit.state.file, CirclesFakeRepository.nouraFile);
      expect(cubit.state.sessionEnded, isFalse);
    });

    test('a second read that finds the sign-in ended', () async {
      await cubit.load();
      circles.medicalFile = const Error(SessionExpiredFailure());

      await cubit.load();

      expect(cubit.state.file, CirclesFakeRepository.nouraFile);
      expect(cubit.state.sessionEnded, isTrue);
    });

    test('a second read brings the new file', () async {
      await cubit.load();
      final MedicalFile changed = _fileWithContacts(1);
      circles.medicalFile = Success(changed);

      await cubit.load();

      expect(cubit.state.file, changed);
    });

    test('an older read that ends late does not win', () async {
      final Completer<Result<MedicalFile, Failure>> slow =
          Completer<Result<MedicalFile, Failure>>();
      final Completer<Result<MedicalFile, Failure>> fast =
          Completer<Result<MedicalFile, Failure>>();
      circles.queuedFileReads
        ..add(slow.future)
        ..add(fast.future);
      final MedicalFile newer = _fileWithContacts(1);

      final Future<void> first = cubit.load();
      final Future<void> second = cubit.load();
      fast.complete(Success<MedicalFile, Failure>(newer));
      await second;
      slow.complete(
        Success<MedicalFile, Failure>(CirclesFakeRepository.nouraFile),
      );
      await first;

      expect(cubit.state.file, newer);
    });
  });

  group('opening the contact form', () {
    setUp(() async {
      await cubit.load();
    });

    test('a new contact opens an empty form', () {
      cubit.startAdd();

      expect(cubit.state.form, const ContactForm());
      expect(cubit.state.form!.isNew, isTrue);
    });

    test('no form opens before the file is read', () {
      final MedicalFileCubit early = MedicalFileCubit(
        CirclesUseCase(circles),
        'circle-1',
      );
      addTearDown(early.close);

      early.startAdd();
      early.startEdit('contact-1');

      expect(early.state.form, isNull);
    });

    test('no form opens when the patient has five contacts', () async {
      circles.medicalFile = Success(_fileWithContacts(5));
      await cubit.load();

      cubit.startAdd();

      expect(cubit.state.form, isNull);
    });

    test('a second tap on "add" keeps what was typed', () {
      cubit.startAdd();
      cubit.nameChanged('سلمى');

      cubit.startAdd();

      expect(cubit.state.form!.name, 'سلمى');
    });

    test('a contact opens its saved values, with the nine digits', () {
      cubit.startEdit('contact-1');

      expect(
        cubit.state.form,
        const ContactForm(
          contactId: 'contact-1',
          relation: 'son',
          name: 'خالد',
          phone: '512345678',
        ),
      );
      expect(cubit.state.form!.isNew, isFalse);
    });

    test('a contact that is not in the list does not open', () {
      cubit.startEdit('nobody');

      expect(cubit.state.form, isNull);
    });

    test('another contact does not replace the open form', () {
      cubit.startEdit('contact-1');

      cubit.startEdit('contact-2');

      expect(cubit.state.form!.contactId, 'contact-1');
    });

    test('cancel closes the form', () {
      cubit.startAdd();

      cubit.cancelForm();

      expect(cubit.state.form, isNull);
    });

    test('typing without a form changes nothing', () {
      final MedicalFileState before = cubit.state;

      cubit.nameChanged('سلمى');
      cubit.phoneChanged('555555555');
      cubit.relationChosen('wife');

      expect(cubit.state, before);
    });
  });

  group('the phone number', () {
    test('nine digits that start with 5 are valid', () {
      expect(MedicalFileCubit.isValidPhone('512345678'), isTrue);
      expect(MedicalFileCubit.isValidPhone('599999999'), isTrue);
    });

    test('anything else is not', () {
      expect(MedicalFileCubit.isValidPhone(''), isFalse);
      expect(MedicalFileCubit.isValidPhone('51234567'), isFalse);
      expect(MedicalFileCubit.isValidPhone('5123456789'), isFalse);
      expect(MedicalFileCubit.isValidPhone('412345678'), isFalse);
      expect(MedicalFileCubit.isValidPhone('0512345678'), isFalse);
      expect(MedicalFileCubit.isValidPhone('٥١٢٣٤٥٦٧٨'), isFalse);
      expect(MedicalFileCubit.isValidPhone('5123 5678'), isFalse);
    });
  });

  group('saving a contact', () {
    setUp(() async {
      await cubit.load();
    });

    const List<(String?, String, String)> missing = <(String?, String, String)>[
      (null, 'سلمى', '555555555'),
      ('wife', '   ', '555555555'),
      ('wife', 'سلمى', '55555555'),
      ('wife', 'سلمى', '455555555'),
      ('wife', 'سلمى', '٥٥٥٥٥٥٥٥٥'),
    ];
    for (int i = 0; i < missing.length; i++) {
      test('a missing or wrong answer sends nothing (case $i)', () async {
        final (String? relation, String name, String phone) = missing[i];
        cubit.startAdd();
        if (relation != null) cubit.relationChosen(relation);
        cubit.nameChanged(name);
        cubit.phoneChanged(phone);

        final bool saved = await cubit.saveContact();

        expect(saved, isFalse);
        expect(cubit.state.form!.showErrors, isTrue);
        expect(cubit.state.form!.saving, isFalse);
        expect(circles.saveCalls, isEmpty);
      });
    }

    test('without a form there is nothing to save', () async {
      expect(await cubit.saveContact(), isFalse);
      expect(circles.saveCalls, isEmpty);
    });

    test('a new contact is sent with +966 and shown last', () async {
      fillNewContact(name: '  سلمى  ');

      final bool saved = await cubit.saveContact();

      expect(saved, isTrue);
      expect(circles.addedContacts, <ContactDraft>[
        const ContactDraft(
          name: 'سلمى',
          relation: 'wife',
          phoneNumber: '+966555555555',
        ),
      ]);
      expect(cubit.state.form, isNull);
      final List<EmergencyContact> contacts = cubit.state.file!.contacts;
      expect(contacts, hasLength(3));
      expect(contacts.last.id, 'new-contact');
      expect(contacts.last.name, 'سلمى');
    });

    test('a changed contact replaces the old one in place', () async {
      cubit.startEdit('contact-1');
      cubit.nameChanged('خالد بن سعد');

      final bool saved = await cubit.saveContact();

      expect(saved, isTrue);
      expect(circles.changedContacts, <(String, ContactDraft)>[
        (
          'contact-1',
          const ContactDraft(
            name: 'خالد بن سعد',
            relation: 'son',
            phoneNumber: '+966512345678',
          ),
        ),
      ]);
      expect(circles.addedContacts, isEmpty);
      final List<EmergencyContact> contacts = cubit.state.file!.contacts;
      expect(contacts.map((EmergencyContact c) => c.id), <String>[
        'contact-1',
        'contact-2',
      ]);
      expect(contacts.first.name, 'خالد بن سعد');
      expect(cubit.state.form, isNull);
    });

    test('the form is locked while the server answers', () async {
      final Completer<Result<EmergencyContact, Failure>> answer =
          Completer<Result<EmergencyContact, Failure>>();
      circles.pendingContact = answer.future;
      fillNewContact();

      final Future<bool> saving = cubit.saveContact();

      expect(cubit.state.form!.saving, isTrue);
      cubit.cancelForm();
      cubit.nameChanged('غيرها');
      expect(cubit.state.form, isNotNull);
      expect(cubit.state.form!.name, 'سلمى');
      expect(await cubit.saveContact(), isFalse);
      expect(circles.addedContacts, hasLength(1));

      answer.complete(
        const Success<EmergencyContact, Failure>(
          EmergencyContact(
            id: 'contact-9',
            name: 'سلمى',
            relation: 'wife',
            phoneNumber: '+966555555555',
          ),
        ),
      );
      expect(await saving, isTrue);
      expect(cubit.state.form, isNull);
    });

    test('a number that is already a contact says why', () async {
      circles.contactSaved = const Error(DuplicateContactFailure());
      fillNewContact();

      final bool saved = await cubit.saveContact();

      expect(saved, isFalse);
      expect(cubit.state.form!.errorKey, 'circles.duplicate_contact');
      expect(cubit.state.form!.saving, isFalse);
      expect(cubit.state.file!.contacts, hasLength(2));
      expect(circles.medicalFileReads, 1);
    });

    test('typing clears the reason', () async {
      circles.contactSaved = const Error(DuplicateContactFailure());
      fillNewContact();
      await cubit.saveContact();

      cubit.phoneChanged('566666666');

      expect(cubit.state.form!.errorKey, isNull);
    });

    test('a fifth contact added elsewhere reads the list again', () async {
      circles.contactSaved = const Error(TooManyContactsFailure());
      circles.medicalFile = Success(_fileWithContacts(5));
      fillNewContact();

      final bool saved = await cubit.saveContact();
      await settle();

      expect(saved, isFalse);
      expect(circles.medicalFileReads, 2);
      expect(cubit.state.file!.contacts, hasLength(5));
      expect(cubit.state.form!.errorKey, 'circles.too_many_contacts');
    });

    test('a contact that is gone reads the list again', () async {
      circles.contactSaved = const Error(NotFoundFailure());
      cubit.startEdit('contact-1');

      final bool saved = await cubit.saveContact();
      await settle();

      expect(saved, isFalse);
      expect(circles.medicalFileReads, 2);
      expect(cubit.state.form!.errorKey, const NotFoundFailure().messageKey);
    });

    test('an ended sign-in is told to the page', () async {
      circles.contactSaved = const Error(SessionExpiredFailure());
      fillNewContact();

      await cubit.saveContact();

      expect(cubit.state.sessionEnded, isTrue);
    });
  });

  group('removing a contact', () {
    setUp(() async {
      await cubit.load();
    });

    test('the contact of the open form is removed', () async {
      cubit.startEdit('contact-2');

      final bool removed = await cubit.deleteContact();

      expect(removed, isTrue);
      expect(circles.deletedContactIds, <String>['contact-2']);
      expect(cubit.state.file!.contacts, <EmergencyContact>[
        CirclesFakeRepository.khaled,
      ]);
      expect(cubit.state.form, isNull);
    });

    test('a contact removed elsewhere is gone either way', () async {
      circles.contactDeleted = const Error(NotFoundFailure());
      cubit.startEdit('contact-2');

      final bool removed = await cubit.deleteContact();

      expect(removed, isTrue);
      expect(cubit.state.file!.contacts, hasLength(1));
      expect(cubit.state.form, isNull);
    });

    test('any other failure keeps the contact and says why', () async {
      circles.contactDeleted = const Error(ServerFailure());
      cubit.startEdit('contact-2');

      final bool removed = await cubit.deleteContact();

      expect(removed, isFalse);
      expect(cubit.state.file!.contacts, hasLength(2));
      expect(cubit.state.form!.errorKey, 'error.server');
      expect(cubit.state.form!.saving, isFalse);
    });

    test('a new contact has nothing to remove', () async {
      cubit.startAdd();

      expect(await cubit.deleteContact(), isFalse);
      expect(circles.saveCalls, isEmpty);
    });

    test('without a form there is nothing to remove', () async {
      expect(await cubit.deleteContact(), isFalse);
      expect(circles.saveCalls, isEmpty);
    });

    test('an ended sign-in is told to the page', () async {
      circles.contactDeleted = const Error(UnauthorizedFailure());
      cubit.startEdit('contact-2');

      await cubit.deleteContact();

      expect(cubit.state.sessionEnded, isTrue);
    });
  });
}
