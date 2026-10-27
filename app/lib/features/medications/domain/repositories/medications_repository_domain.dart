import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class MedicationsRepositoryDomain {
  Future<Result<List<MedicationPlan>, Failure>> getPlans(String circleId);
  Future<Result<MedicationPlan, Failure>> getPlan(
    String circleId,
    String planId,
  );
  Future<Result<MedicationPlan, Failure>> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  );
  Future<Result<MedicationPlan, Failure>> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  );
  Future<Result<MedicationPlan, Failure>> discontinuePlan(
    String circleId,
    String planId,
  );
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  });
  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  );
}
