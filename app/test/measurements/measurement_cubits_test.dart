import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server answer with the API error [code].
DioException _refused(int status, String code) {
  final RequestOptions options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: <String, Object>{
        'error': <String, Object>{'code': code, 'message': 'test'},
      },
    ),
  );
}

class _Repository extends Fake implements MeasurementsRepositoryDomain {
  final requests = <String, Completer<List<MeasurementReading>>>{};
  final changesController = StreamController<String>.broadcast();
  final recordedController = StreamController<String>.broadcast();
  int readingReads = 0;
  int planReads = 0;
  final occurrenceRanges = <(DateTime, DateTime)>[];
  int records = 0;
  Completer<MeasurementReading>? pendingRecord;
  Object? recordError;
  Object? reviseError;
  Object? followUpError;
  int stops = 0;

  @override
  Future<MeasurementReading> followUp(
    String circleId,
    String readingId,
  ) async => throw followUpError!;

  @override
  Future<MeasurementPlan> stopPlan(String circleId, String planId) async {
    stops++;
    changesController.add(circleId);
    return _plan;
  }

  @override
  Stream<String> get changes => changesController.stream;

  @override
  Stream<String> get recorded => recordedController.stream;

  @override
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) {
    readingReads++;
    final request = Completer<List<MeasurementReading>>();
    requests[circleId] = request;
    return request.future;
  }

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async {
    planReads++;
    return const <MeasurementPlan>[];
  }

  @override
  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  ) async => throw reviseError!;

  @override
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    occurrenceRanges.add((from, to));
    return const <MeasurementOccurrence>[];
  }

  @override
  Future<MeasurementReading> record(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) async {
    records++;
    if (recordError case final Object error?) throw error;
    return pendingRecord!.future;
  }
}

final MeasurementOccurrence _task = MeasurementOccurrence(
  planId: 'plan-1',
  versionId: 'version-1',
  kind: MeasurementKind.glucose,
  scheduledOn: DateTime(2026, 11, 3),
  time: '08:00',
  deadlineAt: DateTime.utc(2026, 11, 3, 6),
  status: MeasurementStatus.due,
);

final MeasurementPlan _plan = MeasurementPlan(
  id: 'plan-1',
  kind: MeasurementKind.glucose,
  version: MeasurementVersion(
    id: 'version-1',
    number: 1,
    effectiveFromOn: DateTime(2026, 11, 1),
    time: '08:00',
    weekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
    missedAfterMinutes: 60,
  ),
  history: const <MeasurementVersion>[],
);

MeasurementPlanDraft get _draft => MeasurementPlanDraft(
  kind: MeasurementKind.glucose,
  times: const <MeasurementTime>[MeasurementTime(time: '08:00')],
  weekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
  startsOn: DateTime(2026, 11, 3),
  missedAfterMinutes: 60,
);

void main() {
  group('MeasurementCubits', () {
    test('switching circles clears the previous patient readings', () async {
      final repository = _Repository();
      final cubit = MeasurementReadingsCubit(MeasurementsUseCase(repository));
      final day = DateTime(2026, 11, 3);
      final first = cubit.load('patient-a', day, day);
      repository.requests['patient-a']!.complete([
        MeasurementReading(
          id: 'reading-a',
          kind: MeasurementKind.glucose,
          outcome: 'read',
          recordedAt: day,
          measuredAt: day,
          valueOne: 120,
        ),
      ]);
      await first;
      expect(cubit.state.readings, hasLength(1));

      final second = cubit.load('patient-b', day, day);
      expect(cubit.state.status, MeasurementLoadStatus.loading);
      expect(cubit.state.readings, isEmpty);
      repository.requests['patient-b']!.complete([]);
      await second;
      await cubit.close();
    });

    group('MeasurementReadingsCubit.record', () {
      // 09:00 in Riyadh (UTC+3).
      final PatientClock clock = PatientClock(
        'Asia/Riyadh',
        clock: () => DateTime.utc(2026, 11, 3, 6),
      );

      test('a time read still to come is refused before the server', () async {
        final repository = _Repository();
        final cubit = MeasurementReadingsCubit(MeasurementsUseCase(repository));
        final day = DateTime(2026, 11, 3);
        final loading = cubit.load('circle-1', day, day);
        repository.requests['circle-1']!.complete([]);
        await loading;

        final String? errorKey = await cubit.record(
          MeasurementReadingDraft(
            kind: MeasurementKind.glucose,
            outcome: 'read',
            measuredAt: clock.momentOf(day, '09:01'),
            valueOne: 110,
          ),
          clock: clock,
        );

        expect(errorKey, 'measurements.future_reading');
        expect(repository.records, 0);
        await cubit.close();
      });

      test('a second tap while one saves records nothing', () async {
        final repository = _Repository()
          ..pendingRecord = Completer<MeasurementReading>();
        final cubit = MeasurementReadingsCubit(MeasurementsUseCase(repository));
        final day = DateTime(2026, 11, 3);
        final loading = cubit.load('circle-1', day, day);
        repository.requests['circle-1']!.complete([]);
        await loading;
        final draft = MeasurementReadingDraft(
          kind: MeasurementKind.glucose,
          outcome: 'read',
          measuredAt: clock.momentOf(day, '08:30'),
          valueOne: 110,
        );

        final first = cubit.record(draft, clock: clock, occurrence: _task);
        expect(
          await cubit.record(draft, clock: clock, occurrence: _task),
          null,
        );
        expect(repository.records, 1);
        repository.pendingRecord!.complete(
          MeasurementReading(
            id: 'reading-1',
            kind: MeasurementKind.glucose,
            outcome: 'read',
            recordedAt: DateTime.utc(2026, 11, 3, 6),
            measuredAt: clock.momentOf(day, '08:30'),
            valueOne: 110,
          ),
        );
        expect(await first, null);
        expect(cubit.state.readings, hasLength(1));
        await cubit.close();
      });

      test('a refused reading returns its message', () async {
        final repository = _Repository()
          ..recordError = _refused(409, 'measurement_record_conflict');
        final cubit = MeasurementReadingsCubit(MeasurementsUseCase(repository));
        final day = DateTime(2026, 11, 3);
        final loading = cubit.load('circle-1', day, day);
        repository.requests['circle-1']!.complete([]);
        await loading;

        final String? errorKey = await cubit.record(
          MeasurementReadingDraft(
            kind: MeasurementKind.glucose,
            outcome: 'read',
            measuredAt: clock.momentOf(day, '08:30'),
            valueOne: 110,
          ),
          clock: clock,
          occurrence: _task,
        );

        expect(errorKey, 'measurements.record_conflict');
        await cubit.close();
      });
    });

    test(
      'a reading saved anywhere in the circle reads the list again',
      () async {
        final repository = _Repository();
        final cubit = MeasurementReadingsCubit(MeasurementsUseCase(repository));
        final day = DateTime(2026, 11, 3);
        final loading = cubit.load('circle-1', day, day);
        repository.requests['circle-1']!.complete([]);
        await loading;
        expect(repository.readingReads, 1);

        repository.recordedController.add('another-circle');
        await pumpEventQueue();
        expect(repository.readingReads, 1);

        repository.recordedController.add('circle-1');
        await pumpEventQueue();
        expect(repository.readingReads, 2);
        repository.requests['circle-1']!.complete([]);
        await cubit.close();
      },
    );

    group('MeasurementTasksCubit', () {
      test('reads two days back through 30 calendar days ahead', () async {
        final repository = _Repository();
        final cubit = MeasurementTasksCubit(MeasurementsUseCase(repository));

        await cubit.load('circle-1', DateTime(2026, 3, 20));

        expect(repository.occurrenceRanges.single, (
          DateTime(2026, 3, 18),
          DateTime(2026, 4, 19),
        ));
        await cubit.close();
      });

      test('reads again when a task or plan of its circle changes', () async {
        final repository = _Repository();
        final cubit = MeasurementTasksCubit(MeasurementsUseCase(repository));
        await cubit.load('circle-1', DateTime(2026, 11, 3));

        repository.recordedController.add('circle-1');
        await pumpEventQueue();
        repository.changesController.add('circle-1');
        await pumpEventQueue();
        repository.changesController.add('another-circle');
        await pumpEventQueue();

        expect(repository.occurrenceRanges, hasLength(3));
        await cubit.close();
      });

      test('a refused skip returns its message', () async {
        final repository = _Repository()
          ..recordError = _refused(422, 'future_measurement_task');
        final cubit = MeasurementTasksCubit(MeasurementsUseCase(repository));
        await cubit.load('circle-1', DateTime(2026, 11, 3));

        expect(
          await cubit.skip(
            _task,
            const MeasurementReadingDraft(
              kind: MeasurementKind.glucose,
              outcome: 'skipped',
            ),
          ),
          'measurements.future_task',
        );
        await cubit.close();
      });
    });

    test('a refused follow-up returns its message', () async {
      final repository = _Repository()
        ..followUpError = _refused(422, 'measurement_within_target');
      final cubit = MeasurementReadingsCubit(MeasurementsUseCase(repository));
      final day = DateTime(2026, 11, 3);
      final loading = cubit.load('circle-1', day, day);
      repository.requests['circle-1']!.complete([]);
      await loading;

      final String? errorKey = await cubit.followUp(
        MeasurementReading(
          id: 'reading-1',
          kind: MeasurementKind.bp,
          outcome: 'read',
          recordedAt: DateTime.utc(2026, 11, 3, 6),
        ),
      );

      expect(errorKey, 'measurements.no_follow_up');
      await cubit.close();
    });

    group('MeasurementPlansCubit', () {
      test('a stop saves once and the plans read again', () async {
        final repository = _Repository();
        final cubit = MeasurementPlansCubit(MeasurementsUseCase(repository));
        await cubit.load('circle-1');

        final first = cubit.stop(_plan);
        expect(await cubit.stop(_plan), isNull);
        expect(await first, isNull);
        await pumpEventQueue();

        expect(repository.stops, 1);
        expect(repository.planReads, 2);
        await cubit.close();
      });

      test('reads again when its circle plans change elsewhere', () async {
        final repository = _Repository();
        final cubit = MeasurementPlansCubit(MeasurementsUseCase(repository));
        await cubit.load('circle-1');

        repository.changesController.add('circle-1');
        await pumpEventQueue();

        expect(repository.planReads, 2);
        await cubit.close();
      });

      test(
        'a plan changed elsewhere returns its message and reads again',
        () async {
          final repository = _Repository()
            ..reviseError = _refused(409, 'measurement_plan_changed');
          final cubit = MeasurementPlansCubit(MeasurementsUseCase(repository));
          await cubit.load('circle-1');

          expect(
            await cubit.revise(_plan, _draft),
            'measurements.plan_changed',
          );
          await pumpEventQueue();

          expect(repository.planReads, 2);
          expect(cubit.state.errorKey, isNull);
          await cubit.close();
        },
      );
    });
  });
}
