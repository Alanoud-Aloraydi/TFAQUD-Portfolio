import 'dart:async';

import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:dio/dio.dart' show DioException, Response;

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

  /// The circle where a reading was just saved or a task answered (here,
  /// or elsewhere when the server says the task is already answered or
  /// gone), so its reminder is taken off and the lists showing it read
  /// again. Apart from [changes], which the calendar also follows: a
  /// reading does not change the calendar.
  Stream<String> get recorded => _recorded.stream;

  /// The normal ranges [circleId]'s patient's readings are judged by, and
  /// the conditions of the medical file that chose them.
  Future<NormalRanges> ranges(String circleId) async {
    final response = await _client.get(
      ApiEndpoints.measurementRanges(circleId),
    );
    return NormalRanges.fromJson(
      (response.data as Map<String, dynamic>)['measurement_ranges']
          as Map<String, dynamic>,
    );
  }

  /// Every plan of [circleId], stopped ones too.
  Future<List<MeasurementPlan>> plans(String circleId) async {
    final response = await _client.get(ApiEndpoints.measurementPlans(circleId));
    final values =
        (response.data as Map<String, dynamic>)['measurement_plans']
            as List<dynamic>;
    return knownMeasurementItems(values, MeasurementPlan.fromJson);
  }

  /// Adds a plan from [draft]; the server refuses a second active plan of
  /// one kind and a start before the patient's today.
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

  /// Changes [plan] from [draft]'s start on; readings already taken keep
  /// the version they were taken under.
  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  ) async {
    final response = await _client.put(
      ApiEndpoints.measurementPlan(circleId, plan.id),
      // The latest version: a change waiting for later is the one changed.
      data: draft.toJson(
        expectedVersion: (plan.pendingVersion ?? plan.version).number,
      ),
    );
    _changes.add(circleId);
    return _plan(response.data);
  }

  /// Stops [planId]: no task after now.
  Future<MeasurementPlan> stopPlan(String circleId, String planId) async {
    final response = await _client.post(
      ApiEndpoints.stopMeasurementPlan(circleId, planId),
    );
    _changes.add(circleId);
    return _plan(response.data);
  }

  /// The tasks of the patient's days [from] to [to], both included.
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _client.get(
      ApiEndpoints.measurementOccurrences(circleId),
      queryParameters: {'from': apiDate(from), 'to': apiDate(to)},
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_occurrences']
            as List<dynamic>;
    return linkNextTasks(
      knownMeasurementItems(values, MeasurementOccurrence.fromJson),
    );
  }

  /// The readings of the patient's days [from] to [to], both included (at
  /// most 32 days, as the server allows).
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _client.get(
      ApiEndpoints.measurementReadings(circleId),
      queryParameters: {'from': apiDate(from), 'to': apiDate(to)},
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_readings']
            as List<dynamic>;
    return knownMeasurementItems(values, MeasurementReading.fromJson);
  }

  /// Every reading of [circleId], for the record export.
  Future<List<MeasurementReading>> allReadings(String circleId) async {
    final response = await _client.get(
      ApiEndpoints.measurementReadingsExport(circleId),
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_readings']
            as List<dynamic>;
    return knownMeasurementItems(values, MeasurementReading.fromJson);
  }

  /// Saves [draft]: the answer to [occurrence], the task the person chose,
  /// or a free reading without it.
  Future<MeasurementReading> record(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) async {
    final Response<dynamic> response;
    try {
      response = occurrence == null
          ? await _client.post(
              ApiEndpoints.measurementReadings(circleId),
              data: draft.toJson(),
            )
          : await _client.put(
              ApiEndpoints.measurementRecord(
                circleId,
                occurrence.versionId,
                apiDate(occurrence.scheduledOn),
                // Which reading time of the day: a plan can have several.
                time: occurrence.time,
              ),
              data: draft.toJson(),
            );
    } on DioException catch (error) {
      // Answered elsewhere already (409), or no longer in its plan (404):
      // the task lists are out of date.
      final int? status = error.response?.statusCode;
      if (occurrence != null && (status == 409 || status == 404)) {
        _recorded.add(circleId);
      }
      rethrow;
    }
    _recorded.add(circleId);
    return MeasurementReading.fromJson(
      (response.data as Map<String, dynamic>)['measurement_reading']
          as Map<String, dynamic>,
    );
  }

  /// Marks [readingId], a reading outside its normal range, as followed up.
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
