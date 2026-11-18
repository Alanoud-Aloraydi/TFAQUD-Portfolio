import 'dart:async';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:dio/dio.dart' show DioException, Response;
import 'package:app/core/network/measurement_endpoints.dart';

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
