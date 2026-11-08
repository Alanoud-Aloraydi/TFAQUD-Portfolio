import 'package:app/core/errors/failure.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// 12:00 in Riyadh on 9 November 2026.
final DateTime _noon = DateTime.utc(2026, 11, 9, 9);

SimplifiedDay _day() => SimplifiedDay(
  circleId: 'c-1',
  circleName: 'دائرتي',
  displayName: 'مريم',
  doses: const <DoseOccurrence>[],
  measurements: const <MeasurementOccurrence>[],
  appointments: const [],
  family: const [],
  reasons: const <String, String>{},
);

final DoseOccurrence _dose = DoseOccurrence(
  planId: 'p',
  scheduleId: 's',
  scheduledOn: DateTime(2026, 11, 9),
  time: '11:30',
  name: 'ميتفورمين',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

MeasurementOccurrence _task(String time, {bool read = false}) =>
    MeasurementOccurrence(
      planId: 'm',
      versionId: 'v',
      kind: MeasurementKind.bp,
      scheduledOn: DateTime(2026, 11, 9),
      time: time,
      deadlineAt: _noon.add(const Duration(hours: 5)),
      status: MeasurementStatus.upcoming,
      record: read
          ? MeasurementReading(
              id: 'r',
              kind: MeasurementKind.bp,
              outcome: 'read',
              recordedAt: _noon,
            )
          : null,
    );

class _UseCase implements SimplifiedModeUseCase {
  final List<Result<SimplifiedDay, Failure>> days =
      <Result<SimplifiedDay, Failure>>[];
  int loads = 0;
  int remindings = 0;
  Result<DoseRecord, Failure> doseResult = Success(
    DoseRecord(id: 'r', outcome: DoseOutcome.taken, recordedAt: _noon),
  );
  final List<DoseOccurrence> taken = <DoseOccurrence>[];
  Result<(List<MeasurementTarget>, List<MeasurementOccurrence>), Failure>
  options = const Success((<MeasurementTarget>[], <MeasurementOccurrence>[]));
  final List<(MeasurementReadingDraft, MeasurementOccurrence?)> recorded =
      <(MeasurementReadingDraft, MeasurementOccurrence?)>[];

  @override
  Future<Result<SimplifiedDay, Failure>> loadDay(DateTime now) async {
    loads++;
    return days.length > 1 ? days.removeAt(0) : days.first;
  }

  @override
  Future<void> keepReminding(SimplifiedDay day) async => remindings++;

  @override
  Future<void> refreshReminders() async {}

  @override
  Future<Result<DoseRecord, Failure>> takeDose(
    String circleId,
    DoseOccurrence dose,
    DateTime takenAt,
  ) async {
    taken.add(dose);
    return doseResult;
  }

  @override
  Future<void> snooze({
    required String circleId,
    required SnoozedTask task,
    required String title,
    required String body,
    required Duration after,
  }) async {}

  @override
  Future<bool> snoozeFromNotification(String tap) async => false;

  @override
  Future<
    Result<(List<MeasurementTarget>, List<MeasurementOccurrence>), Failure>
  >
  measurementOptions(String circleId, DateTime now) async => options;

  @override
  Future<Result<MeasurementReading, Failure>> recordMeasurement(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) async {
    recorded.add((draft, occurrence));
    return Success(
      MeasurementReading(
        id: 'new',
        kind: draft.kind,
        outcome: 'read',
        recordedAt: _noon,
      ),
    );
  }
}

void main() {
  group('the simplified day', () {
    late _UseCase useCase;
    late SimplifiedModeCubit cubit;

    setUp(() {
      useCase = _UseCase();
      cubit = SimplifiedModeCubit(useCase, clock: () => _noon);
    });

    tearDown(() => cubit.close());

    test('a read day is ready, and its reminders are set once', () async {
      useCase.days.add(Success(_day()));
      await cubit.load();
      await cubit.load();
      expect(cubit.state.status, SimplifiedModeStatus.ready);
      expect(cubit.state.schedule, isNotNull);
      expect(useCase.remindings, 1);
    });

    test('a first read that fails is a failure with its reason', () async {
      useCase.days.add(const Error(NetworkFailure()));
      await cubit.load();
      expect(cubit.state.status, SimplifiedModeStatus.failure);
      expect(cubit.state.messageKey, 'error.network');
    });

    test('a later failed read keeps the day on screen', () async {
      useCase.days
        ..add(Success(_day()))
        ..add(const Error(NetworkFailure()));
      await cubit.load();
      await cubit.load();
      expect(cubit.state.status, SimplifiedModeStatus.ready);
      expect(cubit.state.day, isNotNull);
      expect(cubit.state.messageKey, 'error.network');
    });

    test('taking a dose saves it at now and reads the day again', () async {
      useCase.days.add(Success(_day()));
      await cubit.load();
      final DateTime? at = await cubit.takeDose(_dose);
      expect(at, _noon);
      expect(useCase.taken, [_dose]);
      await Future<void>.delayed(Duration.zero);
      expect(useCase.loads, 2);
    });

    test('a refused dose says why and returns no time', () async {
      useCase.days.add(Success(_day()));
      useCase.doseResult = const Error(ConflictFailure());
      await cubit.load();
      expect(await cubit.takeDose(_dose), isNull);
      expect(cubit.state.messageKey, isNotNull);
      expect(cubit.state.saving, isFalse);
    });
  });

  group('recording a measurement', () {
    late _UseCase useCase;

    SimplifiedMeasurementCubit cubitAt(DateTime now) =>
        SimplifiedMeasurementCubit(useCase, 'c-1', clock: () => now);

    setUp(() => useCase = _UseCase());

    test(
      'a kind with neither a target nor a task cannot be recorded',
      () async {
        useCase.options = Success((
          <MeasurementTarget>[
            const MeasurementTarget(
              kind: MeasurementKind.glucose,
              glucoseLow: 80,
              glucoseHigh: 140,
            ),
          ],
          <MeasurementOccurrence>[],
        ));
        final cubit = cubitAt(_noon);
        addTearDown(cubit.close);
        await cubit.load();
        expect(cubit.state.status, SimplifiedMeasurementStatus.ready);
        expect(cubit.state.kinds, [MeasurementKind.glucose]);
      },
    );

    test('a reading answers the task whose time is within the hour', () async {
      useCase.options = Success((
        <MeasurementTarget>[],
        <MeasurementOccurrence>[_task('12:40'), _task('20:00')],
      ));
      final cubit = cubitAt(_noon);
      addTearDown(cubit.close);
      await cubit.load();
      final bool saved = await cubit.save(
        const SimplifiedReading(
          kind: MeasurementKind.bp,
          valueOne: 127,
          valueTwo: 80,
          conditions: ['after_meal', 'stress'],
        ),
      );
      expect(saved, isTrue);
      final (draft, occurrence) = useCase.recorded.single;
      expect(occurrence?.time, '12:40');
      expect(draft.conditions, ['after_meal', 'stress']);
      expect(draft.measuredAt, _noon);
    });

    test('without a task due, a reading is a free one', () async {
      useCase.options = Success((
        <MeasurementTarget>[],
        <MeasurementOccurrence>[_task('11:00', read: true), _task('20:00')],
      ));
      final cubit = cubitAt(_noon);
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.save(
        const SimplifiedReading(
          kind: MeasurementKind.bp,
          valueOne: 127,
          valueTwo: 80,
        ),
      );
      expect(useCase.recorded.single.$2, isNull);
    });

    test('an impossible reading is never sent', () async {
      final cubit = cubitAt(_noon);
      addTearDown(cubit.close);
      await cubit.load();
      final bool saved = await cubit.save(
        const SimplifiedReading(
          kind: MeasurementKind.bp,
          valueOne: 80,
          valueTwo: 127,
        ),
      );
      expect(saved, isFalse);
      expect(useCase.recorded, isEmpty);
    });
  });
}
