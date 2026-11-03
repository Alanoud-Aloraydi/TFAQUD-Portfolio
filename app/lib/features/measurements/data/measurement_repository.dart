import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The server owns plans, readings, and computed measurement tasks.
class MeasurementRepository {
  MeasurementRepository(this._client);

  final DioClient _client;

  Future<List<MeasurementPlan>> plans(String circleId) async {
    final response = await _client.get(ApiEndpoints.measurementPlans(circleId));
    final values =
        (response.data as Map<String, dynamic>)['measurement_plans']
            as List<dynamic>;
    return values
        .map((item) => MeasurementPlan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MeasurementPlan> createPlan(
    String circleId,
    MeasurementPlanDraft draft,
  ) async {
    final response = await _client.post(
      ApiEndpoints.measurementPlans(circleId),
      data: draft.toJson(),
    );
    return _plan(response.data);
  }

  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  ) async {
    final response = await _client.put(
      ApiEndpoints.measurementPlan(circleId, plan.id),
      data: draft.toJson(expectedVersion: plan.version.number),
    );
    return _plan(response.data);
  }

  Future<MeasurementPlan> stopPlan(String circleId, String planId) async {
    final response = await _client.post(
      ApiEndpoints.stopMeasurementPlan(circleId, planId),
    );
    return _plan(response.data);
  }

  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _client.get(
      ApiEndpoints.measurementOccurrences(circleId),
      queryParameters: {
        'from': measurementDate(from),
        'to': measurementDate(to),
      },
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_occurrences']
            as List<dynamic>;
    return values
        .map(
          (item) =>
              MeasurementOccurrence.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _client.get(
      ApiEndpoints.measurementReadings(circleId),
      queryParameters: {
        'from': measurementDate(from),
        'to': measurementDate(to),
      },
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_readings']
            as List<dynamic>;
    return values
        .map(
          (item) => MeasurementReading.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<MeasurementReading>> allReadings(String circleId) async {
    final response = await _client.get(
      ApiEndpoints.measurementReadingsExport(circleId),
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_readings']
            as List<dynamic>;
    return values
        .map(
          (item) => MeasurementReading.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<MeasurementReading> record(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) async {
    final path = occurrence == null
        ? ApiEndpoints.measurementReadings(circleId)
        : ApiEndpoints.measurementRecord(
            circleId,
            occurrence.versionId,
            measurementDate(occurrence.scheduledOn),
          );
    final response = occurrence == null
        ? await _client.post(path, data: draft.toJson())
        : await _client.put(path, data: draft.toJson());
    return MeasurementReading.fromJson(
      (response.data as Map<String, dynamic>)['measurement_reading']
          as Map<String, dynamic>,
    );
  }

  Future<MeasurementReading> followUp(String circleId, String readingId) async {
    final response = await _client.post(
      ApiEndpoints.measurementFollowUp(circleId, readingId),
    );
    return MeasurementReading.fromJson(
      (response.data as Map<String, dynamic>)['measurement_reading']
          as Map<String, dynamic>,
    );
  }

  static MeasurementPlan _plan(Object? data) => MeasurementPlan.fromJson(
    (data as Map<String, dynamic>)['measurement_plan'] as Map<String, dynamic>,
  );
}
