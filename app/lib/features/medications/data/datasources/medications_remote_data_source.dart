import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/medications/data/datasources/medication_dose_requests.dart';
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

/// The requests of «سجّل جرعة الآن»: recording an extra dose, and those of
/// a range of days.
mixin MedicationExtraDoseRequests {
  DioClient get client;

  Future<ExtraDose> recordExtraDose(
    String circleId,
    ExtraDoseDraft draft,
  ) async {
    final response = await client.post(
      MedicationEndpoints.medicationExtraDoses(circleId),
      data: extraDoseDraftToJson(draft),
    );
    final body = response.data as Map<String, dynamic>;
    return extraDoseFromJson(
      body['medication_extra_dose'] as Map<String, dynamic>,
    );
  }

  Future<List<ExtraDose>> getExtraDoses(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    final response = await client.get(
      MedicationEndpoints.medicationExtraDoses(circleId),
      queryParameters: {
        'from': apiDate(from),
        'to': apiDate(to),
        'plan_id': ?planId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return (body['medication_extra_doses'] as List<dynamic>)
        .map((item) => extraDoseFromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// One extra dose of the API: `{id, plan_id, taken_at, dose_value,
/// dose_unit, recorded_at, recorded_by}`.
ExtraDose extraDoseFromJson(Map<String, dynamic> json) {
  final recordedBy = json['recorded_by'] as Map<String, dynamic>?;
  final String unit = json['dose_unit'] as String;
  return ExtraDose(
    id: json['id'] as String,
    planId: json['plan_id'] as String,
    takenAt: DateTime.parse(json['taken_at'] as String).toLocal(),
    doseValue: double.parse(json['dose_value'] as String),
    doseUnit: unit == 'mL' ? DoseUnit.milliliter : DoseUnit.values.byName(unit),
    recordedByAccountId: recordedBy?['account_id'] as String?,
    recordedByName: recordedBy?['name'] as String?,
    recordedByAvatarCode: recordedBy?['avatar_code'] as String?,
  );
}

/// The body of `POST medication-extra-doses`: the time in UTC, the dose as
/// a number, as a dose time sends it.
Map<String, Object?> extraDoseDraftToJson(ExtraDoseDraft draft) => {
  'plan_id': draft.planId,
  'taken_at': draft.takenAt.toUtc().toIso8601String(),
  'dose_value': draft.doseValue,
  'dose_unit': draft.doseUnit.apiValue,
};

/// The requests about the medicines themselves: reading them, adding one,
/// changing one, ending one, and dropping a change that waits.
mixin MedicationPlanRequests {
  DioClient get client;

  Future<List<MedicationPlanModel>> getPlans(String circleId) async {
    final response = await client.get(
      MedicationEndpoints.medicationPlans(circleId),
    );
    final body = response.data as Map<String, dynamic>;
    final values = body['medication_plans'] as List<dynamic>;
    return values
        .map(
          (item) => MedicationPlanModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<MedicationPlanModel> getPlan(String circleId, String planId) async {
    final response = await client.get(
      MedicationEndpoints.medicationPlan(circleId, planId),
    );
    return onePlan(response.data);
  }

  Future<MedicationPlanModel> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  ) async {
    final response = await client.post(
      MedicationEndpoints.medicationPlans(circleId),
      data: draft.toJson(),
    );
    return onePlan(response.data);
  }

  Future<MedicationPlanModel> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  ) async {
    final response = await client.put(
      MedicationEndpoints.medicationPlan(circleId, planId),
      data: draft.toJson(expectedVersion: expectedVersion),
    );
    return onePlan(response.data);
  }

  Future<MedicationPlanModel> discontinuePlan(
    String circleId,
    String planId,
  ) async {
    final response = await client.post(
      MedicationEndpoints.discontinueMedication(circleId, planId),
    );
    return onePlan(response.data);
  }

  Future<MedicationPlanModel> cancelPendingPlan(
    String circleId,
    String planId,
    int expectedVersion,
  ) async {
    final response = await client.post(
      MedicationEndpoints.cancelPendingMedication(circleId, planId),
      data: {'expected_version_number': expectedVersion},
    );
    return onePlan(response.data);
  }

  /// The one medicine an answer carries, under its own key.
  MedicationPlanModel onePlan(Object? data) {
    final body = data as Map<String, dynamic>;
    return MedicationPlanModel.fromJson(
      body['medication_plan'] as Map<String, dynamic>,
    );
  }
}
