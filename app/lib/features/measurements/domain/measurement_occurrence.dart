import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence_parse.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:equatable/equatable.dart';

/// Describes one expected measurement task.
class MeasurementOccurrence extends Equatable {
  const MeasurementOccurrence({
    required this.planId,
    required this.versionId,
    required this.kind,
    required this.scheduledOn,
    required this.time,
    required this.deadlineAt,
    required this.status,
    this.measurementState,
    this.record,
    this.snooze,
    this.nextAt,
  });

  final String planId;
  final String versionId;
  final MeasurementKind kind;
  final DateTime scheduledOn;
  final String time;
  final DateTime deadlineAt;
  final MeasurementStatus status;

  final String? measurementState;
  final MeasurementReading? record;

  /// Who in the circle put it off, and until when; null when it is not.
  final SharedSnooze? snooze;

  /// The wall time ([wallClockAt]) of the next task of the same kind in
  /// the list it came in ([linkNextTasks]); null for the last one.
  final DateTime? nextAt;

  /// Whether the next task of the same kind is due by [now] (a wall time):
  /// a reading now would answer that one, so this one is only skipped.
  bool supersededAt(DateTime now) => nextAt != null && !now.isBefore(nextAt!);

  /// This task, knowing when the next one of its kind is.
  MeasurementOccurrence withNextAt(DateTime? value) => MeasurementOccurrence(
    planId: planId,
    versionId: versionId,
    kind: kind,
    scheduledOn: scheduledOn,
    time: time,
    deadlineAt: deadlineAt,
    status: status,
    measurementState: measurementState,
    record: record,
    snooze: snooze,
    nextAt: value,
  );

  factory MeasurementOccurrence.fromJson(Map<String, dynamic> json) =>
      parseMeasurementOccurrence(json);

  @override
  List<Object?> get props => [
    planId,
    versionId,
    kind,
    scheduledOn,
    time,
    deadlineAt,
    status,
    measurementState,
    record,
    snooze,
    nextAt,
  ];
}
