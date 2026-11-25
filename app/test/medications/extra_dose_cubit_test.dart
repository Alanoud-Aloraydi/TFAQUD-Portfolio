import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_history_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

void main() {
  group('ExtraDoseCubit', () {
    test('reads the medicines, or keeps why they did not load', () async {
      final repository = _ExtraDoses()
        ..plans = const Error(ServerFailure('error.server'));
      final cubit = ExtraDoseCubit(MedicationsUseCase(repository), 'circle');
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.loadErrorKey, 'error.server');
      expect(cubit.state.plans, isNull);

      repository.plans = const Success(<MedicationPlan>[]);
      await cubit.load();
      expect(cubit.state.loadErrorKey, isNull);
      expect(cubit.state.plans, isEmpty);
    });

    test('sends one dose, and a second tap on its way sends none', () async {
      final repository = _ExtraDoses();
      final cubit = ExtraDoseCubit(MedicationsUseCase(repository), 'circle');
      addTearDown(cubit.close);
      final answer = Completer<Result<ExtraDose, Failure>>();
      repository.answer = answer.future;

      final first = cubit.record(_draft);
      expect(cubit.state.saving, isTrue);
      expect(await cubit.record(_draft), isFalse);
      answer.complete(Success(_dose));

      expect(await first, isTrue);
      expect(cubit.state.saving, isFalse);
      expect(repository.sent, <ExtraDoseDraft>[_draft]);
    });

    test('a refused dose says why until the sheet changes', () async {
      final repository = _ExtraDoses()
        ..answer = Future.value(
          const Error(ServerFailure('medications.future_taken_time')),
        );
      final cubit = ExtraDoseCubit(MedicationsUseCase(repository), 'circle');
      addTearDown(cubit.close);

      expect(await cubit.record(_draft), isFalse);
      expect(cubit.state.errorKey, 'medications.future_taken_time');
      cubit.clearError();
      expect(cubit.state.errorKey, isNull);
    });
  });

  group('ExtraDoseHistoryCubit', () {
    test('reads three months back, a month at a time', () async {
      final repository = _ExtraDoses()..history = <ExtraDose>[_dose];
      final cubit = ExtraDoseHistoryCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);

      await cubit.load('circle', 'plan', DateTime(2026, 11, 19));

      expect(cubit.state, <ExtraDose>[_dose, _dose, _dose]);
      expect(repository.ranges, <(DateTime, DateTime)>[
        (DateTime(2026, 10, 20), DateTime(2026, 11, 19)),
        (DateTime(2026, 9, 19), DateTime(2026, 10, 19)),
        (DateTime(2026, 8, 19), DateTime(2026, 9, 18)),
      ]);
    });

    test('a month that fails keeps what was read', () async {
      final repository = _ExtraDoses()
        ..history = <ExtraDose>[_dose]
        ..failFrom = 1;
      final cubit = ExtraDoseHistoryCubit(MedicationsUseCase(repository));
      addTearDown(cubit.close);

      await cubit.load('circle', 'plan', DateTime(2026, 11, 19));

      expect(cubit.state, <ExtraDose>[_dose]);
      expect(repository.ranges, hasLength(2));
    });
  });
}

final ExtraDoseDraft _draft = ExtraDoseDraft(
  planId: 'plan',
  takenAt: DateTime.utc(2026, 11, 19, 9),
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

final ExtraDose _dose = ExtraDose(
  id: 'dose',
  planId: 'plan',
  takenAt: DateTime.utc(2026, 11, 19, 9),
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

class _ExtraDoses extends Fake implements MedicationsRepository {
  Result<List<MedicationPlan>, Failure> plans = const Success(
    <MedicationPlan>[],
  );
  Future<Result<ExtraDose, Failure>>? answer;
  final List<ExtraDoseDraft> sent = <ExtraDoseDraft>[];
  List<ExtraDose> history = <ExtraDose>[];
  final List<(DateTime, DateTime)> ranges = <(DateTime, DateTime)>[];

  /// The month, counted from 0, from which the reads fail.
  int? failFrom;

  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(
    String circleId,
  ) async => plans;

  @override
  Future<Result<ExtraDose, Failure>> recordExtraDose(
    String circleId,
    ExtraDoseDraft draft,
  ) {
    sent.add(draft);
    return answer ?? Future.value(Success(_dose));
  }

  @override
  Future<Result<List<ExtraDose>, Failure>> getExtraDoses(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    ranges.add((from, to));
    final int? fail = failFrom;
    if (fail != null && ranges.length > fail) {
      return const Error(ServerFailure());
    }
    return Success(history);
  }
}
