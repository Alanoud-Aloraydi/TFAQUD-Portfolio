import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class MedicationsUseCase {
  MedicationsUseCase(this._repository);

  final MedicationsRepositoryDomain _repository;

  Future<Result<List<MedicationPlan>, Failure>> getPlans(String circleId) =>
      _repository.getPlans(circleId);

  Future<Result<MedicationPlan, Failure>> getPlan(
    String circleId,
    String planId,
  ) => _repository.getPlan(circleId, planId);

  Future<Result<MedicationPlan, Failure>> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  ) => _repository.createPlan(circleId, draft);

  Future<Result<MedicationPlan, Failure>> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  ) => _repository.revisePlan(circleId, planId, expectedVersion, draft);

  Future<Result<MedicationPlan, Failure>> discontinuePlan(
    String circleId,
    String planId,
  ) => _repository.discontinuePlan(circleId, planId);

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
  ) => _repository.recordDose(circleId, occurrence, record);
}
