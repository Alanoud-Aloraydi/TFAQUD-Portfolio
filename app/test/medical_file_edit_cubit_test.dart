import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';

void main() {
  late CirclesFakeRepository circles;
  late MedicalFileEditCubit cubit;

  final MedicalFile noura = CirclesFakeRepository.nouraFile;

  setUp(() {
    circles = CirclesFakeRepository();
    cubit = MedicalFileEditCubit(CirclesUseCase(circles), 'circle-1');
  });

  tearDown(() => cubit.close());

  group('reading the file', () {
    test('starts in the loading state', () {
      expect(cubit.state.status, MedicalFileEditStatus.loading);
    });

    test('fills the page with the saved values', () async {
      await cubit.load();

      expect(cubit.state.status, MedicalFileEditStatus.ready);
      expect(cubit.state.file, noura);
      expect(cubit.state.firstName, 'نورة');
      expect(cubit.state.lastName, 'العتيبي');
      expect(cubit.state.birthDate, DateTime(1954, 6, 5));
      expect(cubit.state.city, 'بريدة');
      expect(cubit.state.form, MedicalForm.fromProfile(noura.profile));
      expect(cubit.state.form.bloodType, 'O+');
      expect(cubit.state.form.conditions, <String>{'diabetes'});
      expect(cubit.state.form.noAllergies, isTrue);
    });

    test('a failed read shows the reason', () async {
      circles.medicalFile = const Error(ServerFailure());

      await cubit.load();

      expect(cubit.state.status, MedicalFileEditStatus.failure);
      expect(cubit.state.messageKey, 'error.server');
      expect(cubit.state.file, isNull);
    });

    test('an ended sign-in is told to the page', () async {
      circles.medicalFile = const Error(SessionExpiredFailure());

      await cubit.load();

      expect(cubit.state.sessionEnded, isTrue);
    });

    test('the names are editable only without an account', () async {
      await cubit.load();
      expect(cubit.state.namesEditable, isTrue);

      circles.medicalFile = Success(CirclesFakeRepository.nouraWithAccount);
      await cubit.load();
      expect(cubit.state.namesEditable, isFalse);
    });
  });

  group('saving, a patient without an account', () {
    setUp(() async {
      await cubit.load();
    });

    test('nothing changed is saved without a call', () async {
      expect(await cubit.save(), isTrue);

      expect(circles.saveCalls, isEmpty);
    });

    test('a new blood type sends only the health answers', () async {
      cubit.chooseBloodType('A+');

      expect(await cubit.save(), isTrue);

      expect(circles.saveCalls, <String>['profile']);
      expect(circles.profileUpdates.single.bloodType, 'A+');
      expect(cubit.state.file!.profile.bloodType, 'A+');
      expect(cubit.state.saving, isFalse);
    });

    test('a second tap on the blood type clears the answer', () async {
      cubit.chooseBloodType('O+');

      expect(await cubit.save(), isTrue);

      expect(circles.profileUpdates.single.bloodType, isNull);
      expect(cubit.state.file!.profile.bloodType, isNull);
    });

    test('the conditions and the allergies are sent as the design shows them',
        () async {
      cubit.toggleCondition('diabetes');
      cubit.toggleCondition('heart');
      cubit.toggleNoAllergies();
      cubit.toggleMedication('penicillin');
      cubit.toggleFood('milk');

      expect(await cubit.save(), isTrue);

      final MedicalProfileDraft sent = circles.profileUpdates.single;
      expect(sent.conditions?.codes, <String>['heart']);
      expect(sent.allergies?.medication, <String>['penicillin']);
      expect(sent.allergies?.food, <String>['milk']);
    });

    test('a new birth date keeps the city and the coordinates', () async {
      cubit.birthDateChanged(DateTime(1955, 1, 2));

      expect(await cubit.save(), isTrue);

      expect(circles.saveCalls, <String>['patient']);
      expect(
        circles.patientUpdates.single,
        PatientUpdate(
          birthDate: DateTime(1955, 1, 2),
          city: 'بريدة',
          firstName: 'نورة',
          lastName: 'العتيبي',
          latitude: 26.33,
          longitude: 43.97,
        ),
      );
      expect(cubit.state.file!.patient.birthDate, DateTime(1955, 1, 2));
    });

    test('a new city drops the old coordinates', () async {
      cubit.cityChanged('الرياض');

      expect(await cubit.save(), isTrue);

      final PatientUpdate sent = circles.patientUpdates.single;
      expect(sent.city, 'الرياض');
      expect(sent.latitude, isNull);
      expect(sent.longitude, isNull);
      expect(cubit.state.file!.patient.latitude, isNull);
      expect(cubit.state.file!.patient.longitude, isNull);
    });

    test('new names are sent trimmed', () async {
      cubit.firstNameChanged('  منيرة ');
      cubit.lastNameChanged(' القحطاني  ');

      expect(await cubit.save(), isTrue);

      final PatientUpdate sent = circles.patientUpdates.single;
      expect(sent.firstName, 'منيرة');
      expect(sent.lastName, 'القحطاني');
      expect(cubit.state.file!.patient.fullName, 'منيرة القحطاني');
    });

    test('an empty name is not saved', () async {
      cubit.firstNameChanged('   ');

      expect(await cubit.save(), isFalse);

      expect(cubit.state.showErrors, isTrue);
      expect(circles.saveCalls, isEmpty);
    });

    test('"other" without its text is not saved', () async {
      cubit.toggleCondition('other');

      expect(await cubit.save(), isFalse);

      expect(cubit.state.showErrors, isTrue);
      expect(circles.saveCalls, isEmpty);
    });

    test('typing the text of "other" makes it valid', () async {
      cubit.toggleCondition('other');
      await cubit.save();

      cubit.conditionOtherChanged('نقرس');

      expect(await cubit.save(), isTrue);
      expect(circles.profileUpdates.single.conditions?.other, 'نقرس');
    });

    test('both parts are saved, the basic data first', () async {
      cubit.cityChanged('جدة');
      cubit.chooseBloodType('B+');

      expect(await cubit.save(), isTrue);

      expect(circles.saveCalls, <String>['patient', 'profile']);
      expect(cubit.state.file!.patient.city, 'جدة');
      expect(cubit.state.file!.profile.bloodType, 'B+');
    });

    test('a refused basic data stops before the health answers', () async {
      circles.patientUpdated = const Error(InvalidBirthDateFailure());
      cubit.birthDateChanged(DateTime(1960, 1, 1));
      cubit.chooseBloodType('B+');

      expect(await cubit.save(), isFalse);

      expect(circles.saveCalls, <String>['patient']);
      expect(cubit.state.errorKey, 'circles.invalid_birth_date');
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.file, noura);
    });

    test('the basic data stays saved when the health answers fail', () async {
      circles.profileSaved = const Error(ServerFailure());
      cubit.cityChanged('جدة');
      cubit.chooseBloodType('B+');

      expect(await cubit.save(), isFalse);

      expect(circles.saveCalls, <String>['patient', 'profile']);
      expect(cubit.state.errorKey, 'error.server');
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.file!.patient.city, 'جدة');
      expect(cubit.state.file!.profile.bloodType, 'O+');
      // What the user chose is still on the page.
      expect(cubit.state.city, 'جدة');
      expect(cubit.state.form.bloodType, 'B+');
    });

    test('a second try sends only the part that failed', () async {
      circles.profileSaved = const Error(ServerFailure());
      cubit.cityChanged('جدة');
      cubit.chooseBloodType('B+');
      await cubit.save();
      circles.profileSaved = null;

      expect(await cubit.save(), isTrue);

      expect(circles.saveCalls, <String>['patient', 'profile', 'profile']);
      expect(circles.patientUpdates, hasLength(1));
      expect(cubit.state.file!.profile.bloodType, 'B+');
      expect(cubit.state.errorKey, isNull);
    });

    test('typing clears the reason of the last failure', () async {
      circles.patientUpdated = const Error(ServerFailure());
      cubit.cityChanged('جدة');
      await cubit.save();
      expect(cubit.state.errorKey, isNotNull);

      cubit.cityChanged('الرياض');

      expect(cubit.state.errorKey, isNull);
    });

    test('an ended sign-in is told to the page', () async {
      circles.patientUpdated = const Error(UnauthorizedFailure());
      cubit.cityChanged('جدة');

      await cubit.save();

      expect(cubit.state.sessionEnded, isTrue);
    });
  });

  group('saving, a patient with an account', () {
    setUp(() async {
      circles.medicalFile = Success(CirclesFakeRepository.nouraWithAccount);
      await cubit.load();
    });

    test('the names are never sent', () async {
      cubit.cityChanged('الرياض');

      expect(await cubit.save(), isTrue);

      final PatientUpdate sent = circles.patientUpdates.single;
      expect(sent.firstName, isNull);
      expect(sent.lastName, isNull);
    });

    test('a typed name is no change, and is not required', () async {
      cubit.firstNameChanged('');

      expect(await cubit.save(), isTrue);

      expect(circles.saveCalls, isEmpty);
    });
  });

  group('saving before the file is read', () {
    test('is refused', () async {
      expect(await cubit.save(), isFalse);

      expect(circles.saveCalls, isEmpty);
    });
  });
}
