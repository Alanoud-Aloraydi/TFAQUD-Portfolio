import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';
import '../support/home_fakes.dart';

/// An account that onboarding completed: it holds its birth date and city.
final AccountSummary _onboarded = AccountSummary(
  firstName: 'Reem',
  lastName: 'Alahmadi',
  birthDate: DateTime(1990, 3, 4),
  city: 'الرياض',
);

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

  /// The birth date and city of an account made before onboarding asked.
  void typeBasics(CreateCircleCubit target) {
    target.birthDateChanged(DateTime(1964, 3, 12));
    target.cityChanged('الرياض');
  }

  group('the account', () {
    test('is waited for: no create while it loads', () async {
      expect(cubit.state.accountLoad, AccountLoad.loading);
      expect(cubit.state.busy, isTrue);
      typeBasics(cubit);
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(circles.requests, isEmpty);
      await cubit.loadAccount();
      expect(cubit.state.busy, isFalse);
    });

    test('its name is the first name and the last name together', () async {
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
      expect(cubit.state.busy, isFalse);
      circles.account = const Success(CirclesFakeRepository.reem);
      await cubit.loadAccount();
      expect(cubit.state.accountLoad, AccountLoad.loaded);
    });

    test('after a failure the typed birth date and city are sent', () async {
      circles.account = const Error(NetworkFailure());
      await cubit.loadAccount();
      expect(cubit.state.asksBasics, isTrue);
      typeBasics(cubit);
      expect(await cubit.create(presetName: 'رعايتي'), isTrue);
      expect(circles.requests.single.birthDate, DateTime(1964, 3, 12));
    });

    test('an ended session is reported', () async {
      circles.account = const Error(SessionExpiredFailure());
      await cubit.loadAccount();
      expect(cubit.state.sessionEnded, isTrue);
    });

    test('is not read for a patient without the app', () async {
      final CreateCircleCubit patient = CreateCircleCubit(
        CirclesUseCase(circles),
        home,
        flow: CircleFlow.patient,
      );
      addTearDown(patient.close);
      expect(patient.state.accountLoad, AccountLoad.notNeeded);
      expect(patient.state.busy, isFalse);
      circles.account = const Error(NetworkFailure());
      await patient.loadAccount();
      expect(patient.state.accountLoad, AccountLoad.notNeeded);
    });
  });

  group('an account that already has a circle', () {
    const AccountSummary owner = AccountSummary(
      firstName: 'Reem',
      lastName: 'Alahmadi',
      patientCircleId: 'old-circle',
    );

    test(
      'is known as soon as the account loads, and home loads again',
      () async {
        circles.account = const Success(owner);
        final Future<String?> signal = home.changes.first;
        await cubit.loadAccount();
        expect(cubit.state.alreadyHasCircle, isTrue);
        expect(await signal, isNull);
      },
    );

    test('sends nothing', () async {
      circles.account = const Success(owner);
      await cubit.loadAccount();
      typeBasics(cubit);
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.errorKey, 'circles.already_has_circle');
      expect(circles.requests, isEmpty);
    });
  });

  group('a circle for your own care', () {
    setUp(() => cubit.loadAccount());

    test('needs a birth date and a city when the account has none', () async {
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.showErrors, isTrue);
      cubit.birthDateChanged(DateTime(1964, 3, 12));
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(circles.requests, isEmpty);
      cubit.cityChanged('جدة');
      expect(await cubit.create(presetName: 'رعايتي'), isTrue);
      expect(cubit.state.showErrors, isFalse);
    });

    test('the chosen chip gives the circle its name', () async {
      cubit.choosePreset(NamePreset.health);
      typeBasics(cubit);
      expect(await cubit.create(presetName: ' صحتي '), isTrue);
      expect(circles.requests.single.name, 'صحتي');
    });

    test('"another name" needs the typed name, without outer spaces', () async {
      cubit.choosePreset(NamePreset.other);
      typeBasics(cubit);
      expect(await cubit.create(presetName: 'اسم آخر'), isFalse);
      expect(cubit.state.showErrors, isTrue);
      cubit.customNameChanged('   ');
      expect(await cubit.create(presetName: 'اسم آخر'), isFalse);
      cubit.customNameChanged('  صحة أمي  ');
      expect(await cubit.create(presetName: 'اسم آخر'), isTrue);
      expect(circles.requests.single.name, 'صحة أمي');
    });

    test('sends the name, the birth date and the city', () async {
      typeBasics(cubit);
      expect(await cubit.create(presetName: 'رعايتي'), isTrue);
      expect(
        circles.requests.single,
        NewSelfCircle(
          name: 'رعايتي',
          birthDate: DateTime(1964, 3, 12),
          city: 'الرياض',
        ),
      );
      expect(cubit.state.status, CreateStatus.created);
      expect(cubit.state.switchToSimplified, isFalse);
    });

    test(
      'tells every home screen to load again and select the new circle',
      () async {
        typeBasics(cubit);
        final Future<String?> signal = home.changes.first;
        expect(await cubit.create(presetName: 'رعايتي'), isTrue);
        expect(await signal, CirclesFakeRepository.newCircle.id);
      },
    );

    test('a failure keeps the answers and shows its text', () async {
      typeBasics(cubit);
      circles.created = const Error(ProfileIncompleteFailure());
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.status, CreateStatus.idle);
      expect(cubit.state.errorKey, 'circles.profile_incomplete');
      expect(cubit.state.city, 'الرياض');
      expect(cubit.state.sessionEnded, isFalse);
    });

    test('"already has a circle" also makes home screens load again', () async {
      typeBasics(cubit);
      final Future<String?> signal = home.changes.first;
      circles.created = const Error(AlreadyHasCircleFailure());
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.errorKey, 'circles.already_has_circle');
      // No circle to select: the value is null.
      expect(await signal, isNull);
    });

    test('an ended session is reported', () async {
      typeBasics(cubit);
      circles.created = const Error(UnauthorizedFailure());
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(cubit.state.sessionEnded, isTrue);
    });

    test('a second tap while saving sends nothing more', () async {
      typeBasics(cubit);
      final Completer<Result<CareCircleSummary, Failure>> wait =
          Completer<Result<CareCircleSummary, Failure>>();
      circles.pending = wait.future;
      final Future<bool> first = cubit.create(presetName: 'رعايتي');
      expect(cubit.state.busy, isTrue);
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      wait.complete(const Success(CirclesFakeRepository.newCircle));
      expect(await first, isTrue);
      expect(circles.requests, hasLength(1));
    });

    test('a tap after the circle was created sends nothing more', () async {
      typeBasics(cubit);
      expect(await cubit.create(presetName: 'رعايتي'), isTrue);
      expect(await cubit.create(presetName: 'رعايتي'), isFalse);
      expect(circles.requests, hasLength(1));
    });

    test('completion after disposal does not emit or throw', () async {
      typeBasics(cubit);
      final Completer<Result<CareCircleSummary, Failure>> wait =
          Completer<Result<CareCircleSummary, Failure>>();
      circles.pending = wait.future;
      final Future<bool> creating = cubit.create(presetName: 'رعايتي');
      await cubit.close();
      wait.complete(const Success(CirclesFakeRepository.newCircle));
      expect(await creating, isFalse);
    });
  });

  group('an account that onboarding completed', () {
    setUp(() async {
      circles.account = Success(_onboarded);
      await cubit.loadAccount();
    });

    test('is not asked for its birth date and city', () {
      expect(cubit.state.asksBasics, isFalse);
    });

    test("sends the account's birth date and city", () async {
      // A city typed on the page (it shows no field) does not win.
      cubit.cityChanged('جدة');
      expect(await cubit.create(presetName: 'رعايتي'), isTrue);
      final NewSelfCircle sent = circles.requests.single;
      expect(sent.birthDate, DateTime(1990, 3, 4));
      // The city also gives the zone, so it is the account's, not left out.
      expect(sent.city, 'الرياض');
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

    test('needs both names, the birth date and the city', () async {
      expect(await patient.create(), isFalse);
      expect(patient.state.showErrors, isTrue);
      patient.patientFirstNameChanged('نورة');
      patient.birthDateChanged(DateTime(1954, 6, 5));
      patient.cityChanged('بريدة');
      // The last name is still missing.
      expect(await patient.create(), isFalse);
      patient.patientLastNameChanged('   ');
      expect(await patient.create(), isFalse);
      expect(circles.patientCircles, isEmpty);
      patient.patientLastNameChanged('العتيبي');
      expect(await patient.create(), isTrue);
      expect(patient.state.showErrors, isFalse);
    });

    test('creates the circle with the names, the date and the city', () async {
      patient.patientFirstNameChanged('  نورة ');
      patient.patientLastNameChanged(' العتيبي  ');
      patient.birthDateChanged(DateTime(1954, 6, 5));
      patient.cityChanged('بريدة');

      expect(await patient.create(), isTrue);

      expect(
        circles.patientCircles.single,
        NewPatientCircle(
          patientFirstName: 'نورة',
          patientLastName: 'العتيبي',
          birthDate: DateTime(1954, 6, 5),
          city: 'بريدة',
        ),
      );
      // It is not a circle for the person's own care.
      expect(circles.requests, isEmpty);
      expect(patient.state.status, CreateStatus.created);
    });

    test(
      'tells every home screen to load again and select the new circle',
      () async {
        fillPatient();
        final Future<String?> signal = home.changes.first;
        expect(await patient.create(), isTrue);
        expect(await signal, CirclesFakeRepository.newCircle.id);
      },
    );

    test('a refusal keeps the answers and shows its text', () async {
      fillPatient();
      circles.createdPatient = const Error(ModeConflictFailure());
      expect(await patient.create(), isFalse);
      expect(patient.state.status, CreateStatus.idle);
      expect(patient.state.errorKey, 'circles.mode_conflict');
      expect(patient.state.patientFirstName, 'نورة');
    });
  });

  group('a circle the patient agreed to', () {
    late CreateCircleCubit approved;

    setUp(() async {
      approved = CreateCircleCubit(
        CirclesUseCase(circles),
        home,
        flow: CircleFlow.approved,
        request: CirclesFakeRepository.agreedByNoura,
      );
      await approved.loadAccount();
    });

    tearDown(() => approved.close());

    void typePatientBasics() {
      approved.birthDateChanged(DateTime(1954, 6, 5));
      approved.cityChanged('بريدة');
    }

    test('the patient names the circle, as they would their own', () async {
      typePatientBasics();
      approved.choosePreset(NamePreset.other);
      expect(await approved.create(presetName: 'اسم آخر'), isFalse);
      approved.customNameChanged('  دائرتي الصحية ');
      expect(await approved.create(presetName: 'اسم آخر'), isTrue);
      expect(circles.completions.single.name, 'دائرتي الصحية');
    });

    test('needs the birth date and the city', () async {
      expect(await approved.create(presetName: 'رعايتي'), isFalse);
      expect(approved.state.showErrors, isTrue);
      approved.birthDateChanged(DateTime(1954, 6, 5));
      expect(await approved.create(presetName: 'رعايتي'), isFalse);
      expect(circles.completions, isEmpty);
    });

    test('stops for an account that already has a circle', () async {
      circles.account = const Success(
        AccountSummary(
          firstName: 'Noura',
          lastName: 'Alotaibi',
          patientCircleId: 'old-circle',
        ),
      );
      await approved.loadAccount();
      typePatientBasics();
      expect(await approved.create(presetName: 'رعايتي'), isFalse);
      expect(circles.completions, isEmpty);
    });

    test(
      'completes this request with the name, the date and the city',
      () async {
        typePatientBasics();
        approved.choosePreset(NamePreset.health);

        expect(await approved.create(presetName: 'صحتي'), isTrue);

        expect(circles.completedIds, <String>['request-in-1']);
        expect(
          circles.completions.single,
          CompleteCircleRequest(
            name: 'صحتي',
            birthDate: DateTime(1954, 6, 5),
            city: 'بريدة',
          ),
        );
        // It creates neither of the other two kinds of circle.
        expect(circles.requests, isEmpty);
        expect(circles.patientCircles, isEmpty);
        expect(approved.state.status, CreateStatus.created);
        // A detailed account stays on its normal "circle created" path.
        expect(approved.state.switchToSimplified, isFalse);
      },
    );

    test(
      'a newly simplified account switches to the simplified home',
      () async {
        circles.completed = const Success((
          CirclesFakeRepository.newCircle,
          CircleAppMode.simplified,
        ));
        typePatientBasics();
        expect(await approved.create(presetName: 'رعايتي'), isTrue);
        expect(approved.state.switchToSimplified, isTrue);
      },
    );

    test(
      'tells every home screen to load again and select the new circle',
      () async {
        typePatientBasics();
        final Future<String?> signal = home.changes.first;
        expect(await approved.create(presetName: 'رعايتي'), isTrue);
        expect(await signal, CirclesFakeRepository.newCircle.id);
      },
    );

    test('a second tap while completing sends nothing more', () async {
      typePatientBasics();
      final Completer<Result<(CareCircleSummary, CircleAppMode), Failure>>
      wait = Completer<Result<(CareCircleSummary, CircleAppMode), Failure>>();
      circles.pendingCompleted = wait.future;
      final Future<bool> first = approved.create(presetName: 'رعايتي');
      expect(await approved.create(presetName: 'رعايتي'), isFalse);
      wait.complete(
        const Success((
          CirclesFakeRepository.newCircle,
          CircleAppMode.detailed,
        )),
      );
      expect(await first, isTrue);
      expect(circles.completions, hasLength(1));
    });

    test('without a request nothing is sent', () async {
      final CreateCircleCubit lost = CreateCircleCubit(
        CirclesUseCase(circles),
        home,
        flow: CircleFlow.approved,
      );
      addTearDown(lost.close);
      await lost.loadAccount();
      lost.birthDateChanged(DateTime(1954, 6, 5));
      lost.cityChanged('بريدة');
      expect(await lost.create(presetName: 'رعايتي'), isFalse);
      expect(lost.state.errorKey, 'error.invalid_data');
      expect(circles.completions, isEmpty);
    });

    test(
      'a request that is gone shows its own text and keeps the answers',
      () async {
        typePatientBasics();
        circles.completed = const Error(RequestUnavailableFailure());
        expect(await approved.create(presetName: 'رعايتي'), isFalse);
        expect(approved.state.status, CreateStatus.idle);
        expect(approved.state.errorKey, 'circles.request_unavailable');
        expect(approved.state.city, 'بريدة');
      },
    );
  });
}
