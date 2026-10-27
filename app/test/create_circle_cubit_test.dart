import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';
import 'support/home_fakes.dart';

void main() {
  late CirclesFakeRepository circles;
  late HomeUseCase home;
  late CreateCircleCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    home = HomeUseCase(HomeFakeRepository());
    cubit = CreateCircleCubit(
      CirclesUseCase(circles),
      home,
      flow: CircleFlow.self,
    );
  });

  tearDown(() => cubit.close());

  /// The first step, complete.
  void fillBasics() {
    cubit.birthDateChanged(DateTime(1964, 3, 12));
    cubit.cityChanged('الرياض');
    expect(cubit.continueFromBasics(presetName: 'رعايتي'), isTrue);
  }

  group('an account that already has a circle', () {
    const AccountSummary owner = AccountSummary(
      firstName: 'Reem',
      lastName: 'Alahmadi',
      patientCircleId: 'old-circle',
    );

    test('is known as soon as the account loads, and home loads again',
        () async {
      circles.account = const Success(owner);
      final Future<String?> signal = home.changes.first;
      await cubit.loadAccount();
      expect(cubit.state.alreadyHasCircle, isTrue);
      expect(await signal, isNull);
    });

    test('cannot go on from the first step', () async {
      circles.account = const Success(owner);
      await cubit.loadAccount();
      cubit.birthDateChanged(DateTime(1964, 3, 12));
      cubit.cityChanged('الرياض');
      expect(cubit.continueFromBasics(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.circleName, isEmpty);
    });

    test('sends nothing when the last step is reached anyway', () async {
      circles.account = const Success(owner);
      await cubit.loadAccount();
      expect(await cubit.create(), isFalse);
      expect(cubit.state.errorKey, 'circles.already_has_circle');
      expect(circles.requests, isEmpty);
    });

    test('a failed account load does not block the pages', () async {
      circles.account = const Error(NetworkFailure());
      await cubit.loadAccount();
      expect(cubit.state.alreadyHasCircle, isFalse);
    });
  });

  group('account name', () {
    test('is the first name and the last name together', () async {
      await cubit.loadAccount();
      expect(cubit.state.accountLoad, AccountLoad.loaded);
      expect(cubit.state.fullName, 'Reem Alahmadi');
      expect(cubit.state.alreadyHasCircle, isFalse);
    });

    test('a failure is shown and can be tried again', () async {
      circles.account = const Error(NetworkFailure());
      await cubit.loadAccount();
      expect(cubit.state.accountLoad, AccountLoad.failed);
      expect(cubit.state.sessionEnded, isFalse);
      circles.account = const Success(CirclesFakeRepository.reem);
      await cubit.loadAccount();
      expect(cubit.state.accountLoad, AccountLoad.loaded);
    });

    test('an ended session is reported', () async {
      circles.account = const Error(SessionExpiredFailure());
      await cubit.loadAccount();
      expect(cubit.state.sessionEnded, isTrue);
    });
  });

  group('step 1: basic details', () {
    test('need a birth date and a city', () {
      expect(cubit.continueFromBasics(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.showErrors, isTrue);
      cubit.birthDateChanged(DateTime(1964, 3, 12));
      expect(cubit.continueFromBasics(presetName: 'رعايتي'), isFalse);
      cubit.cityChanged('جدة');
      expect(cubit.continueFromBasics(presetName: 'رعايتي'), isTrue);
      expect(cubit.state.showErrors, isFalse);
      expect(cubit.state.circleName, 'رعايتي');
      expect(cubit.state.basicsComplete, isTrue);
    });

    test('the chosen chip gives the circle its name', () {
      cubit.choosePreset(NamePreset.health);
      cubit.birthDateChanged(DateTime(1990, 1, 1));
      cubit.cityChanged('جدة');
      expect(cubit.continueFromBasics(presetName: 'صحتي'), isTrue);
      expect(cubit.state.circleName, 'صحتي');
    });

    test('"another name" needs the typed name, without outer spaces', () {
      cubit.choosePreset(NamePreset.other);
      cubit.birthDateChanged(DateTime(1990, 1, 1));
      cubit.cityChanged('جدة');
      expect(cubit.continueFromBasics(presetName: 'اسم آخر'), isFalse);
      cubit.customNameChanged('   ');
      expect(cubit.continueFromBasics(presetName: 'اسم آخر'), isFalse);
      cubit.customNameChanged('  صحة أمي  ');
      expect(cubit.continueFromBasics(presetName: 'اسم آخر'), isTrue);
      expect(cubit.state.circleName, 'صحة أمي');
    });
  });

  group('step 2: health condition', () {
    test('a second tap on the blood type clears it', () {
      cubit.chooseBloodType('O+');
      expect(cubit.state.bloodType, 'O+');
      cubit.chooseBloodType('A-');
      expect(cubit.state.bloodType, 'A-');
      cubit.chooseBloodType('A-');
      expect(cubit.state.bloodType, isNull);
    });

    test('"none" stands alone', () {
      cubit.toggleCondition('diabetes');
      cubit.toggleCondition('heart');
      cubit.toggleCondition('none');
      expect(cubit.state.conditions, <String>{'none'});
      cubit.toggleCondition('asthma');
      expect(cubit.state.conditions, <String>{'asthma'});
    });

    test('a second tap on a condition clears it', () {
      cubit.toggleCondition('diabetes');
      cubit.toggleCondition('diabetes');
      expect(cubit.state.conditions, isEmpty);
    });

    test('"other" needs its text, and turning it off drops the text', () {
      cubit.toggleCondition('other');
      expect(cubit.continueFromHealth(), isFalse);
      expect(cubit.state.showErrors, isTrue);
      cubit.conditionOtherChanged('  Gout ');
      expect(cubit.continueFromHealth(), isTrue);
      cubit.toggleCondition('other');
      expect(cubit.state.conditionOther, '');
    });

    test('skip drops the answers of the step', () {
      cubit.chooseBloodType('O+');
      cubit.toggleCondition('other');
      cubit.conditionOtherChanged('Gout');
      cubit.skipHealth();
      expect(cubit.state.bloodType, isNull);
      expect(cubit.state.conditions, isEmpty);
      expect(cubit.state.conditionOther, '');
    });
  });

  group('step 3: allergies', () {
    test('"no allergies" stands alone', () {
      cubit.toggleMedication('penicillin');
      cubit.toggleFood('milk');
      cubit.toggleNoAllergies();
      expect(cubit.state.noAllergies, isTrue);
      expect(cubit.state.medication, isEmpty);
      expect(cubit.state.food, isEmpty);
      cubit.toggleFood('eggs');
      expect(cubit.state.noAllergies, isFalse);
      expect(cubit.state.food, <String>{'eggs'});
    });

    test('"other" of the medicines and of the foods need their own text',
        () async {
      fillBasics();
      cubit.toggleMedication('other');
      expect(await cubit.create(), isFalse);
      expect(cubit.state.showErrors, isTrue);
      expect(circles.requests, isEmpty);
      cubit.medicationOtherChanged('Iodine');
      cubit.toggleFood('other');
      expect(await cubit.create(), isFalse);
      expect(circles.requests, isEmpty);
      cubit.foodOtherChanged('Kiwi');
      expect(await cubit.create(), isTrue);
    });
  });

  group('create', () {
    test('sends the answers in the order of the design, trimmed', () async {
      fillBasics();
      cubit.chooseBloodType('O+');
      // Chosen in a different order than the design's.
      cubit.toggleCondition('other');
      cubit.toggleCondition('diabetes');
      cubit.conditionOtherChanged('  Gout ');
      cubit.toggleMedication('penicillin');
      cubit.toggleFood('other');
      cubit.toggleFood('milk');
      cubit.foodOtherChanged(' Kiwi ');

      expect(await cubit.create(), isTrue);

      final request = circles.requests.single;
      expect(request.name, 'رعايتي');
      expect(request.birthDate, DateTime(1964, 3, 12));
      expect(request.city, 'الرياض');
      expect(
        request.medicalProfile,
        const MedicalProfileDraft(
          bloodType: 'O+',
          conditions: ConditionsDraft.listed(
            codes: <String>['diabetes', 'other'],
            other: 'Gout',
          ),
          allergies: AllergiesDraft.listed(
            medication: <String>['penicillin'],
            food: <String>['milk', 'other'],
            otherFood: 'Kiwi',
          ),
        ),
      );
      expect(cubit.state.status, CreateStatus.created);
    });

    test('sends the "none" answers', () async {
      fillBasics();
      cubit.toggleCondition('none');
      cubit.toggleNoAllergies();
      expect(await cubit.create(), isTrue);
      expect(
        circles.requests.single.medicalProfile,
        const MedicalProfileDraft(
          conditions: ConditionsDraft.none(),
          allergies: AllergiesDraft.none(),
        ),
      );
    });

    test('sends no medical profile when no health question was answered',
        () async {
      fillBasics();
      expect(await cubit.create(), isTrue);
      expect(circles.requests.single.medicalProfile, isNull);
    });

    test('skipping the allergies drops them but keeps the rest', () async {
      fillBasics();
      cubit.chooseBloodType('A+');
      cubit.toggleMedication('sulfa');
      expect(await cubit.create(skipAllergies: true), isTrue);
      expect(
        circles.requests.single.medicalProfile,
        const MedicalProfileDraft(bloodType: 'A+'),
      );
    });

    test('tells every home screen to load again and select the new circle',
        () async {
      fillBasics();
      final Future<String?> signal = home.changes.first;
      expect(await cubit.create(), isTrue);
      expect(await signal, CirclesFakeRepository.newCircle.id);
    });

    test('a failure keeps the answers and shows its text', () async {
      fillBasics();
      cubit.chooseBloodType('O+');
      circles.created = const Error(ProfileIncompleteFailure());
      expect(await cubit.create(), isFalse);
      expect(cubit.state.status, CreateStatus.idle);
      expect(cubit.state.errorKey, 'circles.profile_incomplete');
      expect(cubit.state.bloodType, 'O+');
      expect(cubit.state.sessionEnded, isFalse);
    });

    test('"already has a circle" also makes home screens load again', () async {
      fillBasics();
      final Future<String?> signal = home.changes.first;
      circles.created = const Error(AlreadyHasCircleFailure());
      expect(await cubit.create(), isFalse);
      expect(cubit.state.errorKey, 'circles.already_has_circle');
      // No circle to select: the value is null.
      expect(await signal, isNull);
    });

    test('an ended session is reported', () async {
      fillBasics();
      circles.created = const Error(UnauthorizedFailure());
      expect(await cubit.create(), isFalse);
      expect(cubit.state.sessionEnded, isTrue);
    });

    test('a second tap while saving sends nothing more', () async {
      fillBasics();
      final Completer<Result<CareCircleSummary, Failure>> wait =
          Completer<Result<CareCircleSummary, Failure>>();
      circles.pending = wait.future;
      final Future<bool> first = cubit.create();
      expect(await cubit.create(), isFalse);
      wait.complete(const Success(CirclesFakeRepository.newCircle));
      expect(await first, isTrue);
      expect(circles.requests, hasLength(1));
    });

    test('without the first step nothing is sent', () async {
      expect(await cubit.create(), isFalse);
      expect(cubit.state.errorKey, 'error.invalid_data');
      expect(circles.requests, isEmpty);
    });

    test('completion after disposal does not emit or throw', () async {
      fillBasics();
      final Completer<Result<CareCircleSummary, Failure>> wait =
          Completer<Result<CareCircleSummary, Failure>>();
      circles.pending = wait.future;
      final Future<bool> creating = cubit.create();
      await cubit.close();
      wait.complete(const Success(CirclesFakeRepository.newCircle));
      expect(await creating, isFalse);
    });
  });

  group('a circle for a patient without the app', () {
    late CreateCircleCubit patient;

    setUp(() {
      patient = CreateCircleCubit(
        CirclesUseCase(circles),
        home,
        flow: CircleFlow.patient,
      );
    });

    tearDown(() => patient.close());

    /// The names, the birth date and the city, typed.
    void fillPatient() {
      patient.patientFirstNameChanged('نورة');
      patient.patientLastNameChanged('العتيبي');
      patient.birthDateChanged(DateTime(1954, 6, 5));
      patient.cityChanged('بريدة');
    }

    test('the first step needs both names, the birth date and the city', () {
      expect(patient.continueFromPatientBasics(labelName: 'أمي'), isFalse);
      expect(patient.state.showErrors, isTrue);
      patient.patientFirstNameChanged('نورة');
      patient.birthDateChanged(DateTime(1954, 6, 5));
      patient.cityChanged('بريدة');
      // The last name is still missing.
      expect(patient.continueFromPatientBasics(labelName: 'أمي'), isFalse);
      patient.patientLastNameChanged('   ');
      expect(patient.continueFromPatientBasics(labelName: 'أمي'), isFalse);
      patient.patientLastNameChanged('العتيبي');
      expect(patient.continueFromPatientBasics(labelName: 'أمي'), isTrue);
      expect(patient.state.showErrors, isFalse);
    });

    test('the circle is named with the label and the first name', () {
      fillPatient();
      expect(patient.continueFromPatientBasics(labelName: 'أمي'), isTrue);
      expect(patient.state.circleName, 'أمي نورة');
      expect(patient.state.basicsComplete, isTrue);
    });

    test('a label of your own needs its text, without outer spaces', () {
      fillPatient();
      patient.chooseLabel(CircleLabel.other);
      expect(patient.continueFromPatientBasics(labelName: 'اسم آخر'), isFalse);
      patient.customLabelChanged('   ');
      expect(patient.continueFromPatientBasics(labelName: 'اسم آخر'), isFalse);
      patient.customLabelChanged('  عمي ');
      expect(patient.continueFromPatientBasics(labelName: 'اسم آخر'), isTrue);
      expect(patient.state.circleName, 'عمي نورة');
    });

    test('a very long label and first name still make an accepted name', () {
      patient.patientFirstNameChanged('ب' * CreateCircleCubit.maxNameLength);
      patient.patientLastNameChanged('العتيبي');
      patient.birthDateChanged(DateTime(1954, 6, 5));
      patient.cityChanged('بريدة');
      patient.chooseLabel(CircleLabel.other);
      patient.customLabelChanged('ا' * CircleNames.maxLabelLength);
      expect(patient.continueFromPatientBasics(labelName: 'اسم آخر'), isTrue);
      expect(patient.state.circleName.length, CircleNames.maxLength);
    });

    test('creates the circle with the names, the date and the city', () async {
      fillPatient();
      patient.continueFromPatientBasics(labelName: 'أمي');
      patient.chooseBloodType('O+');

      expect(await patient.create(), isTrue);

      final NewPatientCircle sent = circles.patientCircles.single;
      expect(sent.name, 'أمي نورة');
      expect(sent.patientFirstName, 'نورة');
      expect(sent.patientLastName, 'العتيبي');
      expect(sent.birthDate, DateTime(1954, 6, 5));
      expect(sent.city, 'بريدة');
      expect(sent.medicalProfile, const MedicalProfileDraft(bloodType: 'O+'));
      // It is not a circle for your own care.
      expect(circles.requests, isEmpty);
      expect(patient.state.status, CreateStatus.created);
    });

    test('sends the names without outer spaces', () async {
      patient.patientFirstNameChanged('  نورة ');
      patient.patientLastNameChanged(' العتيبي  ');
      patient.birthDateChanged(DateTime(1954, 6, 5));
      patient.cityChanged('بريدة');
      patient.continueFromPatientBasics(labelName: 'أمي');
      expect(await patient.create(), isTrue);
      expect(circles.patientCircles.single.patientFirstName, 'نورة');
      expect(circles.patientCircles.single.patientLastName, 'العتيبي');
      expect(circles.patientCircles.single.name, 'أمي نورة');
    });

    test('without the first step nothing is sent', () async {
      expect(await patient.create(), isFalse);
      expect(patient.state.errorKey, 'error.invalid_data');
      expect(circles.patientCircles, isEmpty);
    });

    test('tells every home screen to load again and select the new circle',
        () async {
      fillPatient();
      patient.continueFromPatientBasics(labelName: 'أمي');
      final Future<String?> signal = home.changes.first;
      expect(await patient.create(), isTrue);
      expect(await signal, CirclesFakeRepository.newCircle.id);
    });

    test('a refusal keeps the answers and shows its text', () async {
      fillPatient();
      patient.continueFromPatientBasics(labelName: 'أمي');
      circles.createdPatient = const Error(ModeConflictFailure());
      expect(await patient.create(), isFalse);
      expect(patient.state.status, CreateStatus.idle);
      expect(patient.state.errorKey, 'circles.mode_conflict');
      expect(patient.state.patientFirstName, 'نورة');
    });
  });

  group('a circle the patient agreed to', () {
    late CreateCircleCubit approved;

    setUp(() {
      approved = CreateCircleCubit(
        CirclesUseCase(circles),
        home,
        flow: CircleFlow.approved,
        request: CirclesFakeRepository.agreedByNoura,
      );
    });

    tearDown(() => approved.close());

    test('the circle name is the one the sender chose', () {
      expect(approved.state.circleName, 'أمي نورة');
      expect(approved.request, CirclesFakeRepository.agreedByNoura);
    });

    test('the first step needs the birth date and the city', () {
      expect(approved.continueFromApprovedBasics(), isFalse);
      expect(approved.state.showErrors, isTrue);
      approved.birthDateChanged(DateTime(1954, 6, 5));
      expect(approved.continueFromApprovedBasics(), isFalse);
      approved.cityChanged('بريدة');
      expect(approved.continueFromApprovedBasics(), isTrue);
      expect(approved.state.showErrors, isFalse);
    });

    test('the first step stops for an account that already has a circle',
        () async {
      circles.account = const Success(
        AccountSummary(
          firstName: 'Noura',
          lastName: 'Alotaibi',
          patientCircleId: 'old-circle',
        ),
      );
      await approved.loadAccount();
      approved.birthDateChanged(DateTime(1954, 6, 5));
      approved.cityChanged('بريدة');
      expect(approved.continueFromApprovedBasics(), isFalse);
    });

    test('completes the request with the date, the city and the answers',
        () async {
      approved.birthDateChanged(DateTime(1954, 6, 5));
      approved.cityChanged('بريدة');
      approved.chooseBloodType('O+');

      expect(await approved.create(), isTrue);

      expect(circles.completedIds, <String>['request-in-1']);
      final CompleteCircleRequest sent = circles.completions.single;
      expect(sent.birthDate, DateTime(1954, 6, 5));
      expect(sent.city, 'بريدة');
      expect(sent.medicalProfile, const MedicalProfileDraft(bloodType: 'O+'));
      // It creates neither of the other two kinds of circle.
      expect(circles.requests, isEmpty);
      expect(circles.patientCircles, isEmpty);
      expect(approved.state.status, CreateStatus.created);
    });

    test('tells every home screen to load again and select the new circle',
        () async {
      approved.birthDateChanged(DateTime(1954, 6, 5));
      approved.cityChanged('بريدة');
      final Future<String?> signal = home.changes.first;
      expect(await approved.create(), isTrue);
      expect(await signal, CirclesFakeRepository.newCircle.id);
    });

    test('without the first step nothing is sent', () async {
      expect(await approved.create(), isFalse);
      expect(approved.state.errorKey, 'error.invalid_data');
      expect(circles.completions, isEmpty);
    });

    test('without a request nothing is sent', () async {
      final CreateCircleCubit lost = CreateCircleCubit(
        CirclesUseCase(circles),
        home,
        flow: CircleFlow.approved,
      );
      addTearDown(lost.close);
      lost.birthDateChanged(DateTime(1954, 6, 5));
      lost.cityChanged('بريدة');
      expect(await lost.create(), isFalse);
      expect(circles.completions, isEmpty);
    });

    test('a request that is gone shows its own text and keeps the answers',
        () async {
      approved.birthDateChanged(DateTime(1954, 6, 5));
      approved.cityChanged('بريدة');
      circles.completed = const Error(RequestUnavailableFailure());
      expect(await approved.create(), isFalse);
      expect(approved.state.status, CreateStatus.idle);
      expect(approved.state.errorKey, 'circles.request_unavailable');
      expect(approved.state.city, 'بريدة');
    });
  });
}
