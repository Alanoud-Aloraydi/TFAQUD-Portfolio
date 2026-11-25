import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';

/// A reading from the server's JSON.
MeasurementReading parseMeasurementReading(
  Map<String, dynamic> json,
) => MeasurementReading(
  id: json['id'] as String,
  kind: measurementKindFromWire(json['kind']),
  outcome: json['outcome'] as String,
  recordedAt: DateTime.parse(json['recorded_at'] as String),
  measuredAt: json['measured_at'] == null
      ? null
      : DateTime.parse(json['measured_at'] as String),
  valueOne: (json['glucose_value'] ?? json['systolic_value']) as int?,
  valueTwo: json['diastolic_value'] as int?,
  conditions: (json['conditions'] as List<dynamic>).cast<String>(),
  otherCondition: json['other_text'] as String?,
  note: json['note'] as String?,
  skipReasonCode: json['skip_reason_code'] as String?,
  skipReasonNote: json['skip_reason_note'] as String?,
  outsideTarget: json['outside_target'] as bool?,
  level: MeasurementLevel.fromWire(json['level']),
  range: ReadingRange.fromJson(json['normal_range']),
  followedUpAt: json['followed_up_at'] == null
      ? null
      : DateTime.parse(json['followed_up_at'] as String),
  scheduledOn: json['scheduled_on'] == null
      ? null
      : DateTime.parse(json['scheduled_on'] as String),
  scheduledTime: json['scheduled_time'] as String?,
  planVersionId: json['plan_version_id'] as String?,
  recordedByAccountId:
      (json['recorded_by'] as Map<String, dynamic>?)?['account_id'] as String?,
  recordedByName:
      (json['recorded_by'] as Map<String, dynamic>?)?['name'] as String?,
  recordedByAvatarCode:
      (json['recorded_by'] as Map<String, dynamic>?)?['avatar_code'] as String?,
);

/// What tells two readings apart, for [MeasurementReading.props].
List<Object?> measurementReadingProps(MeasurementReading r) => [
  r.id,
  r.kind,
  r.outcome,
  r.recordedAt,
  r.measuredAt,
  r.valueOne,
  r.valueTwo,
  r.conditions,
  r.otherCondition,
  r.note,
  r.skipReasonCode,
  r.skipReasonNote,
  r.outsideTarget,
  r.level,
  r.range,
  r.followedUpAt,
  r.scheduledOn,
  r.scheduledTime,
  r.planVersionId,
  r.recordedByAccountId,
  r.recordedByName,
  r.recordedByAvatarCode,
];

/// Identifies an unrecorded measurement eligible for the next-task card,
/// by the same rule as a dose in `dose_timing.dart`: one still
/// to come always counts, and one whose time has passed counts only today
/// and only until its deadline, after which «يحتاج انتباهك» carries it.
///
/// The server's status is read once; the deadline it sends keeps the answer
/// right after that, the way «جدول اليوم» reads it.
bool measurementIsNextTaskCandidate(MeasurementOccurrence item, DateTime now) {
  if (item.record != null) return false;
  if (item.status != MeasurementStatus.upcoming &&
      item.status != MeasurementStatus.due) {
    return false;
  }
  if (now.isBefore(wallClockAt(item.scheduledOn, item.time))) return true;
  if (now.isAfter(item.deadlineAt)) return false;
  return item.scheduledOn.year == now.year &&
      item.scheduledOn.month == now.month &&
      item.scheduledOn.day == now.day;
}
