import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';

/// A task from the server's JSON.
MeasurementOccurrence parseMeasurementOccurrence(Map<String, dynamic> json) =>
    MeasurementOccurrence(
      planId: json['plan_id'] as String,
      versionId: json['plan_version_id'] as String,
      kind: measurementKindFromWire(json['kind']),
      scheduledOn: DateTime.parse(json['scheduled_on'] as String),
      time: json['time_of_day'] as String,
      deadlineAt: DateTime.parse(json['deadline_at'] as String),
      status: measurementStatusFromWire(json['status']),
      measurementState: json['measurement_state'] as String?,
      record: json['reading'] == null
          ? null
          : MeasurementReading.fromJson(
              json['reading'] as Map<String, dynamic>,
            ),
      snooze: SharedSnooze.fromJson(json['snooze']),
    );
