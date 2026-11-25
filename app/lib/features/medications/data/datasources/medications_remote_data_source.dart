import 'package:app/core/network/dio_client.dart';
import 'package:app/features/medications/data/datasources/medication_dose_requests.dart';
import 'package:app/features/medications/data/datasources/medication_extra_dose_requests.dart';
import 'package:app/features/medications/data/datasources/medication_plan_requests.dart';
import 'package:app/features/medications/data/models/dose_occurrence_model.dart';
import 'package:app/features/medications/data/models/medication_plan_model.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// Sends medications requests to the API.
class MedicationsRemoteDataSource
    with
        MedicationPlanRequests,
        MedicationDoseRequests,
        MedicationExtraDoseRequests
    implements BaseMedicationsRemoteDataSource {
  MedicationsRemoteDataSource(this.client);

  @override
  final DioClient client;
}

/// Sends base medications requests to the API.
abstract class BaseMedicationsRemoteDataSource {
  Future<List<MedicationPlanModel>> getPlans(String circleId);
  Future<MedicationPlanModel> getPlan(String circleId, String planId);
  Future<MedicationPlanModel> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  );
  Future<MedicationPlanModel> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  );
  Future<MedicationPlanModel> discontinuePlan(String circleId, String planId);
  Future<MedicationPlanModel> cancelPendingPlan(
    String circleId,
    String planId,
    int expectedVersion,
  );
  Future<List<DoseOccurrenceModel>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  });
  Future<DoseRecord> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  );
  Future<ExtraDose> recordExtraDose(String circleId, ExtraDoseDraft draft);
  Future<List<ExtraDose>> getExtraDoses(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  });
}
