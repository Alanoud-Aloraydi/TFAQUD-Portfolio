import 'dart:async';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/measurement_endpoints.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:dio/dio.dart' show DioException, Response;

/// The server owns plans, readings, and computed measurement tasks.
class MeasurementsRepositoryImpl
    with
        MeasurementPlanRequests,
        MeasurementDayRequests,
        MeasurementReadingWrites
    implements MeasurementsRepository {
  MeasurementsRepositoryImpl(this.client);

  @override
  final DioClient client;

  @override
  final StreamController<String> planChanges =
      StreamController<String>.broadcast();

  /// The circle whose measurement plans changed, each time the server
  /// accepts a change (so calendar sync can pick it up right away).
  @override
  Stream<String> get changes => planChanges.stream;

  @override
  final StreamController<String> readingRecorded =
      StreamController<String>.broadcast();

  /// The circle where a reading was just saved or a task answered (here,
  /// or elsewhere when the server says the task is already answered or
  /// gone), so its reminder is taken off and the lists showing it read
  /// again. Apart from [changes], which the calendar also follows: a
  /// reading does not change the calendar.
  @override
  Stream<String> get recorded => readingRecorded.stream;

  /// The normal ranges [circleId]'s patient's readings are judged by, and
  /// the conditions of the medical file that chose them.
  @override
  Future<NormalRanges> ranges(String circleId) async {
    final response = await client.get(
      MeasurementEndpoints.measurementRanges(circleId),
    );
    return NormalRanges.fromJson(
      (response.data as Map<String, dynamic>)['measurement_ranges']
          as Map<String, dynamic>,
    );
  }
}

/// The requests that read what happened on the patient's days: the tasks,
/// the readings of a span, the first day with one, and every reading for
/// the record export.
mixin MeasurementDayRequests {
  DioClient get client;

  /// The tasks of the patient's days [from] to [to], both included.
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await client.get(
      MeasurementEndpoints.measurementOccurrences(circleId),
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
    final response = await client.get(
      MeasurementEndpoints.measurementReadings(circleId),
      queryParameters: {'from': apiDate(from), 'to': apiDate(to)},
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_readings']
            as List<dynamic>;
    return knownMeasurementItems(values, MeasurementReading.fromJson);
  }

  /// The patient's first day with a saved reading or skip; null while
  /// there is none.
  Future<DateTime?> firstReadingOn(String circleId) async {
    final response = await client.get(
      MeasurementEndpoints.measurementFirstReading(circleId),
    );
    final Object? day =
        (response.data as Map<String, dynamic>)['first_reading_on'];
    return day is String ? DateTime.tryParse(day) : null;
  }

  /// Every reading of [circleId], for the record export.
  Future<List<MeasurementReading>> allReadings(String circleId) async {
    final response = await client.get(
      MeasurementEndpoints.measurementReadingsExport(circleId),
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_readings']
            as List<dynamic>;
    return knownMeasurementItems(values, MeasurementReading.fromJson);
  }
}

/// The requests that write a reading: saving one, and marking one outside
/// its range as followed up. A saved or already answered task is announced
/// on [readingRecorded].
mixin MeasurementReadingWrites {
  DioClient get client;

  /// Where the circle of a saved reading or answered task is announced.
  StreamController<String> get readingRecorded;

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
          ? await client.post(
              MeasurementEndpoints.measurementReadings(circleId),
              data: draft.toJson(),
            )
          : await client.put(
              MeasurementEndpoints.measurementRecord(
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
        readingRecorded.add(circleId);
      }
      rethrow;
    }
    readingRecorded.add(circleId);
    return MeasurementReading.fromJson(
      (response.data as Map<String, dynamic>)['measurement_reading']
          as Map<String, dynamic>,
    );
  }

  /// Marks [readingId], a reading outside its normal range, as followed up.
  Future<MeasurementReading> followUp(String circleId, String readingId) async {
    final response = await client.post(
      MeasurementEndpoints.measurementFollowUp(circleId, readingId),
    );
    return MeasurementReading.fromJson(
      (response.data as Map<String, dynamic>)['measurement_reading']
          as Map<String, dynamic>,
    );
  }
}

/// The requests about the plans themselves: reading them, adding one,
/// changing one and stopping one. Each accepted change is announced on
/// [planChanges].
mixin MeasurementPlanRequests {
  DioClient get client;

  /// Where the circle of an accepted plan change is announced.
  StreamController<String> get planChanges;

  /// Every plan of [circleId], stopped ones too.
  Future<List<MeasurementPlan>> plans(String circleId) async {
    final response = await client.get(
      MeasurementEndpoints.measurementPlans(circleId),
    );
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
    final response = await client.post(
      MeasurementEndpoints.measurementPlans(circleId),
      data: draft.toJson(),
    );
    planChanges.add(circleId);
    return _plan(response.data);
  }

  /// Changes [plan] from [draft]'s start on; readings already taken keep
  /// the version they were taken under.
  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  ) async {
    final response = await client.put(
      MeasurementEndpoints.measurementPlan(circleId, plan.id),
      // The latest version: a change waiting for later is the one changed.
      data: draft.toJson(
        expectedVersion: (plan.pendingVersion ?? plan.version).number,
      ),
    );
    planChanges.add(circleId);
    return _plan(response.data);
  }

  /// Stops [planId]: no task after now.
  Future<MeasurementPlan> stopPlan(String circleId, String planId) async {
    final response = await client.post(
      MeasurementEndpoints.stopMeasurementPlan(circleId, planId),
    );
    planChanges.add(circleId);
    return _plan(response.data);
  }

  static MeasurementPlan _plan(Object? data) => MeasurementPlan.fromJson(
    (data as Map<String, dynamic>)['measurement_plan'] as Map<String, dynamic>,
  );
}
