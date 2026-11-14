import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// 12:00 in Riyadh on 9 November 2026.
final DateTime _noon = DateTime.utc(2026, 11, 9, 9);

SimplifiedDay _day({List<DoseOccurrence> doses = const <DoseOccurrence>[]}) =>
    SimplifiedDay(
      circleId: 'c-1',
      circleName: 'دائرتي',
      accountId: 'a-1',
      isPatient: true,
      displayName: 'مريم',
      timeZone: 'Asia/Riyadh',
      doses: doses,
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

MeasurementOccurrence _task(String time) => MeasurementOccurrence(
  planId: 'm',
  versionId: 'v',
  kind: MeasurementKind.bp,
  scheduledOn: DateTime(2026, 11, 9),
  time: time,
  deadlineAt: _noon.add(const Duration(hours: 5)),
  status: MeasurementStatus.upcoming,
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

  /// The tasks put off, as [DoseReminders.snoozes] publishes them.
  final ValueNotifier<Map<String, TaskSnooze>> published =
      ValueNotifier<Map<String, TaskSnooze>>(const <String, TaskSnooze>{});

  /// What was put off, and for how long.
  final List<(String, TodayTask, Duration)> snoozed =
      <(String, TodayTask, Duration)>[];

  @override
  ValueListenable<Map<String, TaskSnooze>> get snoozes => published;

  /// When set, a snooze waits for it, as a slow phone would.
  Completer<void>? snoozeGate;

  @override
  Future<void> snooze(String circleId, TodayTask task, Duration after) async {
    snoozed.add((circleId, task, after));
    await snoozeGate?.future;
    published.value = <String, TaskSnooze>{
      task.snoozeKey(circleId)!: TaskSnooze(
        circleId: circleId,
        task: SnoozedTask.dose,
        subject: task.dose!.name,
        at: _noon.add(after),
      ),
    };
  }

  @override
  Future<bool> snoozeFromNotification(String tap) async => false;

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

    test('the task the patient chose is put off, not another of its kind, '
        'and shows when it comes again', () async {
      final DoseOccurrence earlier = DoseOccurrence(
        planId: 'p-2',
        scheduleId: 's-2',
        scheduledOn: DateTime(2026, 11, 9),
        time: '08:00',
        name: 'أسبرين',
        strengthValue: 81,
        strengthUnit: StrengthUnit.milligram,
        dosageForm: DosageForm.tablet,
        doseValue: 1,
        doseUnit: DoseUnit.tablet,
      );
      useCase.days.add(Success(_day(doses: <DoseOccurrence>[earlier, _dose])));
      await cubit.load();
      // The most recent dose due is 11:30; the patient chose 08:00.
      final TodayTask chosen = cubit.state.schedule!.tasks.firstWhere(
        (task) => task.dose == earlier,
      );

      await cubit.snooze(task: chosen, after: const Duration(minutes: 15));

      expect(useCase.snoozed.single, (
        'c-1',
        chosen,
        const Duration(minutes: 15),
      ));
      expect(
        cubit.state.snoozes[chosen.snoozeKey('c-1')]?.at,
        _noon.add(const Duration(minutes: 15)),
      );
      expect(cubit.state.saving, isFalse);
    });

    test('a second press while a task is being put off does nothing', () async {
      useCase.days.add(Success(_day(doses: <DoseOccurrence>[_dose])));
      await cubit.load();
      final TodayTask task = cubit.state.schedule!.tasks.single;
      useCase.snoozeGate = Completer<void>();

      final Future<void> first = cubit.snooze(
        task: task,
        after: const Duration(minutes: 15),
      );
      expect(cubit.state.saving, isTrue);
      await cubit.snooze(task: task, after: const Duration(minutes: 30));
      useCase.snoozeGate!.complete();
      await first;

      expect(useCase.snoozed.single.$3, const Duration(minutes: 15));
      expect(cubit.state.saving, isFalse);
    });

    test('a task put off in the detailed mode shows here too, and stops '
        'once its reminder came or it was recorded', () async {
      useCase.days.add(Success(_day(doses: <DoseOccurrence>[_dose])));
      await cubit.load();
      final TaskSnooze snooze = TaskSnooze(
        circleId: 'c-1',
        task: SnoozedTask.dose,
        subject: _dose.name,
        at: _noon.add(const Duration(minutes: 30)),
      );

      useCase.published.value = <String, TaskSnooze>{
        doseSnoozeKey('c-1', _dose): snooze,
      };
      expect(cubit.state.snoozes, <String, TaskSnooze>{
        doseSnoozeKey('c-1', _dose): snooze,
      });

      useCase.published.value = const <String, TaskSnooze>{};
      expect(cubit.state.snoozes, isEmpty);
    });

    test('nothing is put off before the day is read', () async {
      final TodayTask task = TodayTask.medication(_dose, TodayTaskStatus.late);

      await cubit.snooze(task: task, after: const Duration(minutes: 15));

      expect(useCase.snoozed, isEmpty);
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

    SimplifiedMeasurementCubit cubitAt(
      DateTime now, {
      MeasurementOccurrence? task,
    }) => SimplifiedMeasurementCubit(
      useCase,
      'c-1',
      task: task,
      clock: () => now,
    );

    const SimplifiedReading bp = SimplifiedReading(
      kind: MeasurementKind.bp,
      valueOne: 127,
      valueTwo: 80,
      conditions: ['after_meal', 'stress'],
    );

    setUp(() => useCase = _UseCase());

    test('a free reading offers both kinds, needing no target', () async {
      final cubit = cubitAt(_noon);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, SimplifiedMeasurementStatus.ready);
      expect(cubit.state.kinds, [MeasurementKind.bp, MeasurementKind.glucose]);
    });

    test('opened for a task, the reading records that task', () async {
      final cubit = cubitAt(_noon, task: _task('20:00'));
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.kinds, [MeasurementKind.bp]);
      expect(await cubit.save(bp), isTrue);
      final (draft, occurrence) = useCase.recorded.single;
      expect(occurrence?.time, '20:00');
      expect(draft.conditions, ['after_meal', 'stress']);
      expect(draft.measuredAt, _noon);
    });

    test('opened freely, a reading stays free while a task is due', () async {
      final cubit = cubitAt(_noon);
      addTearDown(cubit.close);
      await cubit.load();
      expect(await cubit.save(bp), isTrue);
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
