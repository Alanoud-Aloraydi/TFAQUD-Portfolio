import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

void main() {
  group('MedicationsCubit', () {
    test('record filter changes without reloading plans', () {
      final repository = _PlansRepository();
      final cubit = MedicationsCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);

      expect(cubit.state.recordFilter, MedicationRecordFilter.all);
      cubit.setRecordFilter(MedicationRecordFilter.previous);

      expect(cubit.state.recordFilter, MedicationRecordFilter.previous);
      expect(repository.calls, isEmpty);
    });

    test('an older circle response cannot replace the latest circle', () async {
      final repository = _PlansRepository();
      final cubit = MedicationsCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);
      final old = Completer<Result<List<MedicationPlan>, Failure>>();
      final latest = Completer<Result<List<MedicationPlan>, Failure>>();
      repository.responses.addAll([old.future, latest.future]);

      final oldLoad = cubit.load('circle-old');
      final latestLoad = cubit.load('circle-latest');
      latest.complete(const Success([]));
      await latestLoad;
      old.complete(const Error(ServerFailure('error.unknown')));
      await oldLoad;

      expect(repository.calls, ['circle-old', 'circle-latest']);
      expect(cubit.state.status, MedicationsStatus.ready);
      expect(cubit.state.messageKey, isNull);
    });

    test(
      'a change saved on another page reads the list again quietly',
      () async {
        final repository = _PlansRepository();
        final useCase = MedicationsUseCase(repository);
        final cubit = MedicationsCubit(useCase);
        addTearDown(cubit.close);
        repository.responses.addAll([
          Future.value(const Success([])),
          Future.value(const Success([])),
        ]);
        await cubit.load('circle-1');
        final states = <MedicationsStatus>[];
        final listening = cubit.stream.listen((s) => states.add(s.status));
        addTearDown(listening.cancel);

        await useCase.recordDose(
          'circle-1',
          _occurrence(),
          const DoseRecordDraft(outcome: DoseOutcome.skipped),
        );
        await Future<void>.delayed(Duration.zero);

        expect(repository.calls, ['circle-1', 'circle-1']);
        expect(states, isNot(contains(MedicationsStatus.loading)));
      },
    );

    test('a cubit that only saves follows no change', () async {
      final repository = _PlansRepository();
      final useCase = MedicationsUseCase(repository);
      final cubit = MedicationsCubit(useCase)..bind('circle-1');
      addTearDown(cubit.close);

      await useCase.recordDose(
        'circle-1',
        _occurrence(),
        const DoseRecordDraft(outcome: DoseOutcome.skipped),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, isEmpty);
    });
  });
}

DoseOccurrence _occurrence() => DoseOccurrence(
  planId: 'plan-1',
  scheduleId: 'schedule-1',
  scheduledOn: DateTime(2026, 10, 1),
  time: '08:00',
  name: 'Medicine',
  strengthValue: 5,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

class _PlansRepository extends Fake implements MedicationsRepositoryDomain {
  final responses = <Future<Result<List<MedicationPlan>, Failure>>>[];
  final calls = <String>[];

  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(String circleId) {
    calls.add(circleId);
    return responses.removeAt(0);
  }

  @override
  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) async => Success(
    DoseRecord(
      id: 'record-1',
      outcome: record.outcome,
      recordedAt: DateTime.utc(2026, 10, 1),
    ),
  );
}
