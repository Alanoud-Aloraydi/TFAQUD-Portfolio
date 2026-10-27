import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/medications/data/models/dose_occurrence_model.dart';
import 'package:app/features/medications/data/models/medication_plan_model.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:injectable/injectable.dart';

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
}

@LazySingleton(as: BaseMedicationsRemoteDataSource)
class MedicationsRemoteDataSource implements BaseMedicationsRemoteDataSource {
  MedicationsRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<List<MedicationPlanModel>> getPlans(String circleId) async {
    final response = await _client.get(ApiEndpoints.medicationPlans(circleId));
    final body = response.data as Map<String, dynamic>;
    final values = body['medication_plans'] as List<dynamic>;
    return values
        .map(
          (item) => MedicationPlanModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<MedicationPlanModel> getPlan(String circleId, String planId) async {
    final response = await _client.get(
      ApiEndpoints.medicationPlan(circleId, planId),
    );
    return _plan(response.data);
  }

  @override
  Future<MedicationPlanModel> createPlan(
    String circleId,
    MedicationPlanDraft draft,
  ) async {
    final response = await _client.post(
      ApiEndpoints.medicationPlans(circleId),
      data: draft.toJson(),
    );
    return _plan(response.data);
  }

  @override
  Future<MedicationPlanModel> revisePlan(
    String circleId,
    String planId,
    int expectedVersion,
    MedicationPlanDraft draft,
  ) async {
    final response = await _client.put(
      ApiEndpoints.medicationPlan(circleId, planId),
      data: draft.toJson(expectedVersion: expectedVersion),
    );
    return _plan(response.data);
  }

  @override
  Future<MedicationPlanModel> discontinuePlan(
    String circleId,
    String planId,
  ) async {
    final response = await _client.post(
      ApiEndpoints.discontinueMedication(circleId, planId),
    );
    return _plan(response.data);
  }

  @override
  Future<List<DoseOccurrenceModel>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    final response = await _client.get(
      ApiEndpoints.medicationOccurrences(circleId),
      queryParameters: {
        'from': _date(from),
        'to': _date(to),
        'plan_id': ?planId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final values = body['medication_occurrences'] as List<dynamic>;
    return values
        .map(
          (item) => DoseOccurrenceModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<DoseRecord> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) async {
    final response = await _client.put(
      ApiEndpoints.medicationDoseRecord(
        circleId,
        occurrence.scheduleId,
        _date(occurrence.scheduledOn),
      ),
      data: record.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    return DoseRecordModel.fromJson(
      body['medication_dose_record'] as Map<String, dynamic>,
    ).toEntity();
  }

  static MedicationPlanModel _plan(Object? data) {
    final body = data as Map<String, dynamic>;
    return MedicationPlanModel.fromJson(
      body['medication_plan'] as Map<String, dynamic>,
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
