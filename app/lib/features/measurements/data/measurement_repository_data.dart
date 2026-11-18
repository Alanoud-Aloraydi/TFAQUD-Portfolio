import 'dart:async';

import 'package:app/core/network/dio_client.dart';
import 'package:app/features/measurements/data/measurement_day_requests.dart';
import 'package:app/features/measurements/data/measurement_plan_requests.dart';
import 'package:app/features/measurements/data/measurement_reading_writes.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:app/core/network/measurement_endpoints.dart';

/// The server owns plans, readings, and computed measurement tasks.
class MeasurementRepositoryData
    with
        MeasurementPlanRequests,
        MeasurementDayRequests,
        MeasurementReadingWrites
    implements MeasurementRepository {
  MeasurementRepositoryData(this.client);

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
