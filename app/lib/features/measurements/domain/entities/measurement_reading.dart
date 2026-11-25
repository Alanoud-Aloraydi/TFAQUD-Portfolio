import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/measurements/domain/entities/measurement_conditions.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading_codec.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:equatable/equatable.dart';

/// Stores an actual blood pressure or glucose reading.
class MeasurementReading extends Equatable {
  const MeasurementReading({
    required this.id,
    required this.kind,
    required this.outcome,
    required this.recordedAt,
    this.measuredAt,
    this.valueOne,
    this.valueTwo,
    this.conditions = const <String>[],
    this.otherCondition,
    this.note,
    this.skipReasonCode,
    this.skipReasonNote,
    this.outsideTarget,
    this.level,
    this.range,
    this.followedUpAt,
    this.scheduledOn,
    this.scheduledTime,
    this.planVersionId,
    this.recordedByAccountId,
    this.recordedByName,
    this.recordedByAvatarCode,
  });

  final String id;
  final MeasurementKind kind;
  final String outcome;
  final DateTime recordedAt;
  final DateTime? measuredAt;
  final int? valueOne;
  final int? valueTwo;

  /// «ظروف القياس» ([MeasurementConditions]), none or more.
  final List<String> conditions;

  /// What «أخرى» was, in the reader's words; null without it.
  final String? otherCondition;
  final String? note;
  final String? skipReasonCode;
  final String? skipReasonNote;

  /// Outside its normal range ([level] anything but normal); null for a
  /// skip.
  final bool? outsideTarget;

  /// Where it falls in [range]; null for a skip.
  final MeasurementLevel? level;

  /// The normal range it was judged by; null for a skip.
  final ReadingRange? range;
  final DateTime? followedUpAt;
  final DateTime? scheduledOn;

  /// Which reading time of [scheduledOn] it answers («HH:mm»).
  final String? scheduledTime;
  final String? planVersionId;

  /// Who recorded it: null for a reading from before this was tracked.
  final String? recordedByAccountId;
  final String? recordedByName;
  final String? recordedByAvatarCode;

  String get valueText =>
      kind == MeasurementKind.bp ? '$valueOne/$valueTwo' : '$valueOne';

  /// The same reading for a screen reader. A reader says the slash of
  /// «150/80» as «مائل» or drops it; «150 على 80» is how a blood pressure
  /// is said aloud, in the clinic and at home.
  String spokenValue(String over) =>
      kind == MeasurementKind.bp ? '$valueOne $over $valueTwo' : '$valueOne';

  factory MeasurementReading.fromJson(Map<String, dynamic> json) =>
      parseMeasurementReading(json);

  @override
  List<Object?> get props => measurementReadingProps(this);
}

/// The latest moment, not after now on [clock], whose patient wall time is
/// [time] («HH:mm»): today's, or yesterday's while today's is still to
/// come. A reading can only be in the past, so «11:50 م» picked at 12:10
/// after midnight is last night's; the server accepts it for that task.
DateTime latestReadingMoment(PatientClock clock, String time) {
  final DateTime today = clock.today();
  final DateTime moment = clock.momentOf(today, time);
  return clock.wallTime(moment).isAfter(clock.now())
      ? clock.momentOf(addDays(today, -1), time)
      : moment;
}
