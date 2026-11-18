import 'package:app/core/network/dio_client.dart';
import 'package:app/features/medications/data/models/medication_plan_model.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/core/network/medication_endpoints.dart';

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
