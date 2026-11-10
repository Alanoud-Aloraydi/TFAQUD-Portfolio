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
  group('MedicationOccurrencesCubit', () {
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

    test(
      'a medicine that starts after today asks the server nothing',
      () async {
        final repository = _Repository();
        final cubit = MedicationOccurrencesCubit(
          MedicationsUseCase(repository),
        );
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
      },
    );

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
      await cubit.load(
        'circle-1',
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 27),
      );

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

    test('a picked time still to come is refused without the server', () async {
      final repository = _Repository();
      final cubit = MedicationOccurrencesCubit(
        MedicationsUseCase(repository),
        clock: () => DateTime.utc(2026, 10, 1, 9),
      );
      addTearDown(cubit.close);
      final occurrence = _occurrence(DateTime(2026, 10, 1));
      repository.responses.add(Success([occurrence]));
      await cubit.load(
        'circle-1',
        occurrence.scheduledOn,
        occurrence.scheduledOn,
      );

      final message = await cubit.take(
        occurrence,
        DateTime.utc(2026, 10, 1, 10),
      );

      expect(message, 'medications.future_taken_time');
      expect(repository.drafts, isEmpty);
    });

    test('taken now uses the injected clock', () async {
      final repository = _Repository();
      final now = DateTime.utc(2026, 10, 1, 9);
      final cubit = MedicationOccurrencesCubit(
        MedicationsUseCase(repository),
        clock: () => now,
      );
      addTearDown(cubit.close);
      final occurrence = _occurrence(DateTime(2026, 10, 1));
      repository.responses.add(Success([occurrence]));
      repository.saved = DoseRecord(
        id: 'record-1',
        outcome: DoseOutcome.taken,
        takenAt: now,
        recordedAt: now,
      );
      await cubit.load(
        'circle-1',
        occurrence.scheduledOn,
        occurrence.scheduledOn,
      );

      expect(await cubit.take(occurrence), isNull);
      expect(repository.drafts.single.takenAt, now);
    });

    test(
      'a failed answer returns its message, which the Today tab shows',
      () async {
        final repository = _Repository();
        final cubit = MedicationOccurrencesCubit(
          MedicationsUseCase(repository),
        );
        addTearDown(cubit.close);
        final occurrence = _occurrence(DateTime(2026, 10, 1));
        repository.responses.add(Success([occurrence]));
        repository.saveResponse = Future.value(const Error(NetworkFailure()));
        await cubit.load(
          'circle-1',
          occurrence.scheduledOn,
          occurrence.scheduledOn,
        );

        final message = await cubit.record(
          occurrence,
          const DoseRecordDraft(outcome: DoseOutcome.skipped),
        );

        expect(message, 'error.network');
        expect(cubit.state.status, MedicationOccurrencesStatus.ready);
        expect(repository.ranges, hasLength(1));
      },
    );

    test('a dose answered elsewhere reads the range again', () async {
      final repository = _Repository();
      final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);
      final occurrence = _occurrence(DateTime(2026, 10, 1));
      final answered = occurrence.withRecord(
        DoseRecord(
          id: 'other',
          outcome: DoseOutcome.skipped,
          recordedAt: DateTime.utc(2026, 10, 1),
        ),
      );
      repository.responses.addAll([
        Success([occurrence]),
        Success([answered]),
      ]);
      repository.saveResponse = Future.value(
        const Error(ConflictFailure('medications.dose_record_conflict')),
      );
      await cubit.load(
        'circle-1',
        occurrence.scheduledOn,
        occurrence.scheduledOn,
      );

      final message = await cubit.take(occurrence);
      await Future<void>.delayed(Duration.zero);

      expect(message, 'medications.dose_record_conflict');
      expect(repository.ranges, hasLength(2));
      expect(cubit.state.occurrences, [answered]);
    });

    test('a dose gone from its plan says so and reads again', () async {
      final repository = _Repository();
      final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);
      final occurrence = _occurrence(DateTime(2026, 10, 1));
      repository.responses.addAll([
        Success([occurrence]),
        const Success([]),
      ]);
      repository.saveResponse = Future.value(const Error(NotFoundFailure()));
      await cubit.load(
        'circle-1',
        occurrence.scheduledOn,
        occurrence.scheduledOn,
      );

      expect(await cubit.take(occurrence), 'medications.dose_gone');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.occurrences, isEmpty);
    });

    test(
      'a dose answered on another page is read quietly, same circle only',
      () async {
        final repository = _Repository();
        final useCase = MedicationsUseCase(repository);
        final cubit = MedicationOccurrencesCubit(useCase);
        addTearDown(cubit.close);
        final occurrence = _occurrence(DateTime(2026, 10, 1));
        final answered = occurrence.withRecord(
          DoseRecord(
            id: 'other',
            outcome: DoseOutcome.skipped,
            recordedAt: DateTime.utc(2026, 10, 1),
          ),
        );
        repository.responses.addAll([
          Success([occurrence]),
          Success([answered]),
        ]);
        repository.saved = answered.record;
        await cubit.load(
          'circle-1',
          occurrence.scheduledOn,
          occurrence.scheduledOn,
        );
        final states = <MedicationOccurrencesStatus>[];
        final listening = cubit.stream.listen((s) => states.add(s.status));
        addTearDown(listening.cancel);

        // Another circle's change reads nothing.
        await useCase.recordDose(
          'circle-2',
          occurrence,
          const DoseRecordDraft(outcome: DoseOutcome.skipped),
        );
        await Future<void>.delayed(Duration.zero);
        expect(repository.ranges, hasLength(1));

        // This circle's change, saved by another cubit: the list is read again
        // and never shows the loading state in between.
        await useCase.recordDose(
          'circle-1',
          occurrence,
          const DoseRecordDraft(outcome: DoseOutcome.skipped),
        );
        await Future<void>.delayed(Duration.zero);

        expect(repository.ranges, hasLength(2));
        expect(cubit.state.occurrences, [answered]);
        expect(states, isNot(contains(MedicationOccurrencesStatus.loading)));
      },
    );

    test('a quiet reading that fails keeps the doses shown', () async {
      final repository = _Repository();
      final useCase = MedicationsUseCase(repository);
      final cubit = MedicationOccurrencesCubit(useCase);
      addTearDown(cubit.close);
      final occurrence = _occurrence(DateTime(2026, 10, 1));
      repository.responses.addAll([
        Success([occurrence]),
        const Error(NetworkFailure()),
      ]);
      repository.saved = DoseRecord(
        id: 'other',
        outcome: DoseOutcome.skipped,
        recordedAt: DateTime.utc(2026, 10, 1),
      );
      await cubit.load(
        'circle-1',
        occurrence.scheduledOn,
        occurrence.scheduledOn,
      );

      await useCase.recordDose(
        'circle-1',
        occurrence,
        const DoseRecordDraft(outcome: DoseOutcome.skipped),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, MedicationOccurrencesStatus.ready);
      expect(cubit.state.occurrences, [occurrence]);
      expect(cubit.state.messageKey, isNull);
    });

    test(
      'a quiet reading of another circle never shows the old doses',
      () async {
        final repository = _Repository();
        final cubit = MedicationOccurrencesCubit(
          MedicationsUseCase(repository),
        );
        addTearDown(cubit.close);
        final occurrence = _occurrence(DateTime(2026, 10, 1));
        repository.responses.addAll([
          Success([occurrence]),
          const Error(NetworkFailure()),
        ]);
        await cubit.load(
          'circle-1',
          occurrence.scheduledOn,
          occurrence.scheduledOn,
        );

        await cubit.load(
          'circle-2',
          occurrence.scheduledOn,
          occurrence.scheduledOn,
          silent: true,
        );

        expect(cubit.state.status, MedicationOccurrencesStatus.failure);
        expect(cubit.state.occurrences, isEmpty);
      },
    );

    test('earlier pages step by calendar days', () async {
      final repository = _Repository();
      final cubit = MedicationOccurrencesCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);
      repository.responses.addAll([const Success([]), const Success([])]);
      await cubit.load(
        'circle-1',
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 5),
      );
      await cubit.loadEarlier(DateTime(2026, 10, 1));

      expect(repository.ranges[1].$2, DateTime(2026, 11, 1));
      expect(repository.ranges[1].$1, DateTime(2026, 10, 1));
    });
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
  final drafts = <DoseRecordDraft>[];
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
  ) {
    drafts.add(record);
    return saveResponse ?? Future.value(Success(saved!));
  }
}
