import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_task_link.dart';
import 'package:app/core/network/measurement_endpoints.dart';

/// The requests that read what happened on the patient's days: the tasks,
/// the readings of a span, and every reading for the record export.
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
