import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
/// Exposes medications domain operations.
class MedicationsUseCase {
  MedicationsUseCase(this._repository);

  final MedicationsRepositoryDomain _repository;

  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  /// The circle whose medicines or dose records changed, each time the
  /// server accepts a change (the dose reminders are set again).
  Stream<String> get changes => _changes.stream;

  Future<Result<T, Failure>> _changing<T extends Object>(
    String circleId,
    Future<Result<T, Failure>> call,
  ) async {
    final Result<T, Failure> result = await call;
    if (result.isSuccess()) _changes.add(circleId);
    return result;
  }

  Future<Result<List<MedicationPlan>, Failure>> getPlans(String circleId) =>
      _repository.getPlans(circleId);

  Future<Result<MedicationPlan, Failure>> getPlan(
    String circleId,
    String planId,
  ) => _repository.getPlan(circleId, planId);

  Future<Result<MedicationPlan, Failure>> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  ) => _changing(circleId, _repository.createPlan(circleId, draft));

  Future<Result<MedicationPlan, Failure>> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  ) => _changing(
    circleId,
    _repository.revisePlan(circleId, planId, expectedVersion, draft),
  );

  Future<Result<MedicationPlan, Failure>> discontinuePlan(
    String circleId,
    String planId,
  ) => _changing(circleId, _repository.discontinuePlan(circleId, planId));

  Future<Result<MedicationPlan, Failure>> cancelPendingPlan(
    String circleId,
    String planId,
    int expectedVersion,
  ) => _changing(
    circleId,
    _repository.cancelPendingPlan(circleId, planId, expectedVersion),
  );

  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) => _repository.getOccurrences(circleId, from, to, planId: planId);

  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) =>
      _changing(circleId, _repository.recordDose(circleId, occurrence, record));
}
