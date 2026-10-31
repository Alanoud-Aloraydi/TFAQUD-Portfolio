import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

void main() {
  test('loads older occurrences without replacing the recent page', () async {
    final repository = _Repository();
    final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
    addTearDown(cubit.close);
    final recent = _occurrence(DateTime(2026, 10, 1));
    final older = _occurrence(DateTime(2026, 9, 30));
    repository.responses.addAll([
      Success([recent]),
      Success([older]),
    ]);

    await cubit.load(
      'circle-1',
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 27),
      planId: 'plan-1',
    );
    await cubit.loadEarlier(DateTime(2026, 8, 1));

    expect(cubit.state.occurrences, [older, recent]);
    expect(repository.ranges[1].$1, DateTime(2026, 8, 30));
    expect(repository.ranges[1].$2, DateTime(2026, 9, 30));
  });

  test('a medicine that starts after today asks the server nothing', () async {
    final repository = _Repository();
    final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
    addTearDown(cubit.close);

    // From its first day (30 November) to today (31 October): the range
    // ends before it starts, which the server refuses as invalid data.
    await cubit.load(
      'circle-1',
      DateTime(2026, 11, 30),
      DateTime(2026, 10, 31),
      planId: 'plan-1',
    );

    expect(repository.ranges, isEmpty);
    expect(cubit.state.status, MedicationOccurrencesStatus.ready);
    expect(cubit.state.occurrences, isEmpty);
    expect(cubit.state.messageKey, isNull);
    expect(cubit.canLoadEarlier(DateTime(2026, 11, 30)), isFalse);
  });

  test('records an outcome without reloading an oversized range', () async {
    final repository = _Repository();
    final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
    addTearDown(cubit.close);
    final occurrence = _occurrence(DateTime(2026, 10, 1));
    repository.responses.add(Success([occurrence]));
    repository.saved = DoseRecord(
      id: 'record-1',
      outcome: DoseOutcome.skipped,
      recordedAt: DateTime(2026, 10, 2),
    );
    await cubit.load('circle-1', DateTime(2026, 10, 1), DateTime(2026, 10, 27));

    await cubit.record(
      occurrence,
      const DoseRecordDraft(outcome: DoseOutcome.skipped),
    );

    expect(cubit.state.occurrences.single.record, repository.saved);
    expect(repository.ranges, hasLength(1));
  });

  test('identifies the occurrence while its record is being saved', () async {
    final repository = _Repository();
    final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
    addTearDown(cubit.close);
    final occurrence = _occurrence(DateTime(2026, 10, 1));
    final pending = Completer<Result<DoseRecord, Failure>>();
    repository.responses.add(Success([occurrence]));
    repository.saveResponse = pending.future;
    repository.saved = DoseRecord(
      id: 'record-1',
      outcome: DoseOutcome.taken,
      recordedAt: DateTime(2026, 10, 1),
    );
    await cubit.load(
      'circle-1',
      occurrence.scheduledOn,
      occurrence.scheduledOn,
    );

    final recording = cubit.record(
      occurrence,
      DoseRecordDraft(
        outcome: DoseOutcome.taken,
        takenAt: DateTime(2026, 10, 1),
      ),
    );

    expect(cubit.state.recordingOccurrence, occurrence);
    pending.complete(Success(repository.saved!));
    await recording;
    expect(cubit.state.recordingOccurrence, isNull);
  });
}

DoseOccurrence _occurrence(DateTime day) => DoseOccurrence(
  planId: 'plan-1',
  scheduleId: 'schedule-1',
  scheduledOn: day,
  time: '08:00',
  name: 'Medicine',
  strengthValue: 5,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

class _Repository extends Fake implements MedicationsRepositoryDomain {
  final responses = <Result<List<DoseOccurrence>, Failure>>[];
  final ranges = <(DateTime, DateTime)>[];
  DoseRecord? saved;
  Future<Result<DoseRecord, Failure>>? saveResponse;

  @override
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    ranges.add((from, to));
    return responses.removeAt(0);
  }

  @override
  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) => saveResponse ?? Future.value(Success(saved!));
}
