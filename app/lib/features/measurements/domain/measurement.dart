import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported measurement kind values.
enum MeasurementKind {
  glucose,
  bp;

  /// What the server calls it: `glucose` or `blood_pressure`.
  String get wire => this == bp ? 'blood_pressure' : name;
}

/// Defines the supported measurement status values.
enum MeasurementStatus { upcoming, due, missed, read, readLate, skipped }

/// Defines the target range for a measurement type.
class MeasurementTarget extends Equatable {
  const MeasurementTarget({
    required this.kind,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
    this.planId,
  });

  final MeasurementKind kind;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;
  final String? planId;

  factory MeasurementTarget.fromJson(Map<String, dynamic> json) =>
      MeasurementTarget(
        kind: _kind(json['kind']),
        glucoseLow: json['glucose_low'] as int?,
        glucoseHigh: json['glucose_high'] as int?,
        systolicLimit: json['systolic_limit'] as int?,
        diastolicLimit: json['diastolic_limit'] as int?,
        planId: json['plan_id'] as String?,
      );

  @override
  List<Object?> get props => [
    kind,
    glucoseLow,
    glucoseHigh,
    systolicLimit,
    diastolicLimit,
    planId,
  ];
}

/// One planned reading time and its glucose «حالة القياس».
class MeasurementTime extends Equatable {
  const MeasurementTime({required this.time, this.measurementState});

  /// «HH:mm», the patient's wall clock.
  final String time;

  final String? measurementState;

  factory MeasurementTime.fromJson(Map<String, dynamic> json) =>
      MeasurementTime(
        time: json['time_of_day'] as String,
        measurementState: json['measurement_state'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'time_of_day': time,
    'measurement_state': measurementState,
  };

  @override
  List<Object?> get props => [time, measurementState];
}

/// Preserves one effective measurement schedule.
class MeasurementVersion extends Equatable {
  const MeasurementVersion({
    required this.id,
    required this.number,
    required this.effectiveFromOn,
    required this.time,
    required this.weekdays,
    required this.graceMinutes,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
    this.times = const <MeasurementTime>[],
  });

  final String id;
  final int number;
  final DateTime effectiveFromOn;

  /// The first reading time ([readingTimes] has them all).
  final String time;
  final List<int> weekdays;
  final int graceMinutes;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;

  /// The reading times as the server listed them; [readingTimes] is what to
  /// use.
  final List<MeasurementTime> times;

  /// Every reading time of a day, earliest first; the first alone when a
  /// version was built without the list.
  List<MeasurementTime> get readingTimes =>
      times.isEmpty ? <MeasurementTime>[MeasurementTime(time: time)] : times;

  factory MeasurementVersion.fromJson(Map<String, dynamic> json) {
    final List<MeasurementTime> times = (json['times'] as List<dynamic>)
        .map((item) => MeasurementTime.fromJson(item as Map<String, dynamic>))
        .toList();
    return MeasurementVersion(
      id: json['id'] as String,
      number: json['version_number'] as int,
      effectiveFromOn: DateTime.parse(json['effective_from_on'] as String),
      time: times.first.time,
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
      graceMinutes: json['missed_after_minutes'] as int,
      glucoseLow: json['glucose_low'] as int?,
      glucoseHigh: json['glucose_high'] as int?,
      systolicLimit: json['systolic_limit'] as int?,
      diastolicLimit: json['diastolic_limit'] as int?,
      times: times,
    );
  }

  @override
  List<Object?> get props => [
    id,
    number,
    effectiveFromOn,
    time,
    weekdays,
    graceMinutes,
    times,
    glucoseLow,
    glucoseHigh,
    systolicLimit,
    diastolicLimit,
  ];
}

/// Holds a recurring measurement schedule and target.
class MeasurementPlan extends Equatable {
  const MeasurementPlan({
    required this.id,
    required this.kind,
    required this.version,
    required this.history,
    this.pendingVersion,
    this.stoppedAt,
    this.createdByAccountId,
    this.createdByName,
    this.createdByAvatarCode,
    this.lastEditedByName,
  });

  final String id;
  final MeasurementKind kind;
  final MeasurementVersion version;
  final MeasurementVersion? pendingVersion;
  final List<MeasurementVersion> history;
  final DateTime? stoppedAt;

  /// Who added this plan, for tracking; null when it predates this field.
  final String? createdByAccountId;
  final String? createdByName;
  final String? createdByAvatarCode;

  /// Who made the version in effect now; same person as [createdByName]
  /// unless the plan was revised since, or null when it predates this field.
  final String? lastEditedByName;

  factory MeasurementPlan.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    final lastEditedBy = json['last_edited_by'] as Map<String, dynamic>?;
    return MeasurementPlan(
      id: json['id'] as String,
      kind: _kind(json['kind']),
      version: MeasurementVersion.fromJson(
        json['version'] as Map<String, dynamic>,
      ),
      pendingVersion: json['pending_version'] == null
          ? null
          : MeasurementVersion.fromJson(
              json['pending_version'] as Map<String, dynamic>,
            ),
      history: (json['history'] as List<dynamic>)
          .map(
            (value) =>
                MeasurementVersion.fromJson(value as Map<String, dynamic>),
          )
          .toList(),
      stoppedAt: json['stopped_at'] == null
          ? null
          : DateTime.parse(json['stopped_at'] as String),
      createdByAccountId: createdBy?['account_id'] as String?,
      createdByName: createdBy?['name'] as String?,
      createdByAvatarCode: createdBy?['avatar_code'] as String?,
      lastEditedByName: lastEditedBy?['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    version,
    pendingVersion,
    history,
    stoppedAt,
    createdByAccountId,
    createdByName,
    createdByAvatarCode,
    lastEditedByName,
  ];
}

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
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
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
  final bool? outsideTarget;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;
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

  factory MeasurementReading.fromJson(Map<String, dynamic> json) =>
      MeasurementReading(
        id: json['id'] as String,
        kind: _kind(json['kind']),
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
        glucoseLow: json['glucose_low'] as int?,
        glucoseHigh: json['glucose_high'] as int?,
        systolicLimit: json['systolic_limit'] as int?,
        diastolicLimit: json['diastolic_limit'] as int?,
        followedUpAt: json['followed_up_at'] == null
            ? null
            : DateTime.parse(json['followed_up_at'] as String),
        scheduledOn: json['scheduled_on'] == null
            ? null
            : DateTime.parse(json['scheduled_on'] as String),
        scheduledTime: json['scheduled_time'] as String?,
        planVersionId: json['plan_version_id'] as String?,
        recordedByAccountId:
            (json['recorded_by'] as Map<String, dynamic>?)?['account_id']
                as String?,
        recordedByName:
            (json['recorded_by'] as Map<String, dynamic>?)?['name'] as String?,
        recordedByAvatarCode:
            (json['recorded_by'] as Map<String, dynamic>?)?['avatar_code']
                as String?,
      );

  @override
  List<Object?> get props => [
    id,
    kind,
    outcome,
    recordedAt,
    measuredAt,
    valueOne,
    valueTwo,
    conditions,
    otherCondition,
    note,
    skipReasonCode,
    skipReasonNote,
    outsideTarget,
    glucoseLow,
    glucoseHigh,
    systolicLimit,
    diastolicLimit,
    followedUpAt,
    scheduledOn,
    scheduledTime,
    planVersionId,
    recordedByAccountId,
    recordedByName,
    recordedByAvatarCode,
  ];
}

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

  factory MeasurementOccurrence.fromJson(Map<String, dynamic> json) =>
      MeasurementOccurrence(
        planId: json['plan_id'] as String,
        versionId: json['plan_version_id'] as String,
        kind: _kind(json['kind']),
        scheduledOn: DateTime.parse(json['scheduled_on'] as String),
        time: json['time_of_day'] as String,
        deadlineAt: DateTime.parse(json['deadline_at'] as String),
        status: _status(json['status']),
        measurementState: json['measurement_state'] as String?,
        record: json['reading'] == null
            ? null
            : MeasurementReading.fromJson(
                json['reading'] as Map<String, dynamic>,
              ),
        snooze: SharedSnooze.fromJson(json['snooze']),
      );

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
  ];
}

/// Holds editable measurement plan values before saving.
class MeasurementPlanDraft {
  const MeasurementPlanDraft({
    required this.kind,
    required this.times,
    required this.weekdays,
    required this.startsOn,
    required this.graceMinutes,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
  });

  final MeasurementKind kind;

  /// The reading times of a day, one or more.
  final List<MeasurementTime> times;
  final List<int> weekdays;
  final DateTime startsOn;
  final int graceMinutes;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;

  /// One reading time is sent as before (`time_of_day`), so it saves on a
  /// server without several times too; more are sent as `times`, and so is
  /// one with conditions only a list holds. With [expectedVersion] (a
  /// revision: the number of the plan's latest version) [startsOn] is the
  /// day the change takes effect.
  Map<String, dynamic> toJson({int? expectedVersion}) => {
    'kind': kind.wire,
    'times': [for (final MeasurementTime item in times) item.toJson()],
    'weekdays': weekdays,
    'starts_on': apiDate(startsOn),
    'effective_from_on': ?(expectedVersion == null ? null : apiDate(startsOn)),
    'missed_after_minutes': graceMinutes,
    'glucose_low': glucoseLow,
    'glucose_high': glucoseHigh,
    'systolic_limit': systolicLimit,
    'diastolic_limit': diastolicLimit,
    'expected_version_number': ?expectedVersion,
  };
}

/// Holds editable measurement reading values before saving.
class MeasurementReadingDraft {
  const MeasurementReadingDraft({
    required this.kind,
    required this.outcome,
    this.measuredAt,
    this.valueOne,
    this.valueTwo,
    this.conditions = const <String>[],
    this.otherCondition,
    this.note,
    this.skipReasonCode,
    this.skipReasonNote,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
  });

  final MeasurementKind kind;
  final String outcome;
  final DateTime? measuredAt;
  final int? valueOne;
  final int? valueTwo;

  /// «ظروف القياس» ([MeasurementConditions]), none or more.
  final List<String> conditions;

  /// What «أخرى» was, in the reader's words; sent only with «أخرى».
  final String? otherCondition;
  final String? note;
  final String? skipReasonCode;
  final String? skipReasonNote;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'outcome': outcome,
    'measured_at': measuredAt?.toUtc().toIso8601String(),
    if (kind == MeasurementKind.glucose)
      'glucose_value': valueOne
    else ...{
      'systolic_value': valueOne,
      'diastolic_value': valueTwo,
    },
    'conditions': conditions,
    if (otherCondition != null && conditions.contains('other'))
      'other_text': otherCondition,
    'note': note,
    'skip_reason_code': skipReasonCode,
    'skip_reason_note': skipReasonNote,
    'glucose_low': glucoseLow,
    'glucose_high': glucoseHigh,
    'systolic_limit': systolicLimit,
    'diastolic_limit': diastolicLimit,
  };
}

enum MeasurementSkipReason {
  forgotten,
  equipmentUnavailable,
  patientRefused,
  unwell,
  other;

  String get apiValue => switch (this) {
    equipmentUnavailable => 'equipment_unavailable',
    patientRefused => 'patient_refused',
    _ => name,
  };
}

/// A kind or status this app does not know (sent by a newer server).
class UnknownMeasurementValue implements Exception {
  const UnknownMeasurementValue(this.value);

  /// The value as the server sent it.
  final Object? value;

  @override
  String toString() => 'UnknownMeasurementValue($value)';
}

/// [values] parsed by [parse], leaving out an item of a kind or status this
/// app does not know, so one newer item never hides the whole list.
List<T> knownMeasurementItems<T>(
  List<dynamic> values,
  T Function(Map<String, dynamic> json) parse,
) => <T>[
  for (final dynamic item in values)
    ?_known(() => parse(item as Map<String, dynamic>)),
];

T? _known<T>(T Function() parse) {
  try {
    return parse();
  } on UnknownMeasurementValue {
    return null;
  }
}

MeasurementKind _kind(Object? value) =>
    MeasurementKind.values.where((kind) => kind.wire == value).firstOrNull ??
    (throw UnknownMeasurementValue(value));

/// `read_late` → [MeasurementStatus.readLate].
MeasurementStatus _status(Object? value) =>
    MeasurementStatus.values.asNameMap()[value is String
        ? value.replaceAllMapped(
            RegExp('_([a-z])'),
            (match) => match[1]!.toUpperCase(),
          )
        : null] ??
    (throw UnknownMeasurementValue(value));

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
