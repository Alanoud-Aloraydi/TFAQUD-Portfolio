import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';
import 'support/home_fakes.dart';

void main() {
  late CirclesFakeRepository circles;
  late HomeUseCase home;
  late CreateSelfCircleCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    home = HomeUseCase(HomeFakeRepository());
    cubit = CreateSelfCircleCubit(CirclesUseCase(circles), home);
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
}
