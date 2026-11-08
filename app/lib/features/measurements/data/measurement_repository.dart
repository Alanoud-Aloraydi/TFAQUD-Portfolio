import 'dart:async';

import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The server owns plans, readings, and computed measurement tasks.
class MeasurementRepository {
  MeasurementRepository(this._client);

  final DioClient _client;

  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  /// The circle whose measurement plans changed, each time the server
  /// accepts a change (so calendar sync can pick it up right away).
  Stream<String> get changes => _changes.stream;

  final StreamController<String> _recorded =
      StreamController<String>.broadcast();

  /// The circle where a measurement task was just recorded, so its reminder
  /// is taken off. Apart from [changes], which the calendar also follows: a
  /// reading does not change the calendar.
  Stream<String> get recorded => _recorded.stream;

  Future<List<MeasurementTarget>> targets(String circleId) async {
    final response = await _client.get(
      ApiEndpoints.measurementTargets(circleId),
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_targets']
            as List<dynamic>;
    return values
        .map((item) => MeasurementTarget.fromJson(item as Map<String, dynamic>))
        .toList();
  }

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
    _changes.add(circleId);
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
    _changes.add(circleId);
    return _plan(response.data);
  }

  Future<MeasurementPlan> stopPlan(String circleId, String planId) async {
    final response = await _client.post(
      ApiEndpoints.stopMeasurementPlan(circleId, planId),
    );
    _changes.add(circleId);
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
            // Which reading time of the day: a plan can have several.
            time: occurrence.time,
          );
    final response = occurrence == null
        ? await _client.post(path, data: draft.toJson())
        : await _client.put(path, data: draft.toJson());
    if (occurrence != null) _recorded.add(circleId);
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
