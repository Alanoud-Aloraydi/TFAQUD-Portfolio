import 'package:equatable/equatable.dart';

/// Defines the supported measurement kind values.
enum MeasurementKind { glucose, bp }

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
        kind: MeasurementKind.values.byName(json['kind'] as String),
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

/// One reading time of the day («قراءة»), with its glucose context: a
/// glucose plan can read fasting at 07:00 and after a meal at 14:00.
class MeasurementTime extends Equatable {
  const MeasurementTime({required this.time, this.glucoseContext});

  /// «HH:mm» in Riyadh.
  final String time;
  final String? glucoseContext;

  factory MeasurementTime.fromJson(Map<String, dynamic> json) =>
      MeasurementTime(
        time: json['time_of_day'] as String,
        glucoseContext: json['glucose_context'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'time_of_day': time,
    'glucose_context': glucoseContext,
  };

  @override
  List<Object?> get props => [time, glucoseContext];
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
    this.glucoseContext,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
    List<MeasurementTime> times = const <MeasurementTime>[],
  }) : _times = times;

  final String id;
  final int number;
  final DateTime effectiveFromOn;

  /// The first reading time ([readingTimes] has them all).
  final String time;
  final List<int> weekdays;
  final int graceMinutes;
  final String? glucoseContext;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;
  final List<MeasurementTime> _times;

  /// Every reading time of a day, earliest first; one when the plan reads
  /// once a day, or when an older server does not list them.
  List<MeasurementTime> get readingTimes => _times.isEmpty
      ? <MeasurementTime>[
          MeasurementTime(time: time, glucoseContext: glucoseContext),
        ]
      : _times;

  factory MeasurementVersion.fromJson(Map<String, dynamic> json) =>
      MeasurementVersion(
        id: json['id'] as String,
        number: json['number'] as int,
        effectiveFromOn: DateTime.parse(json['effective_from_on'] as String),
        time: json['time_of_day'] as String,
        weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
        graceMinutes: json['grace_minutes'] as int,
        glucoseContext: json['glucose_context'] as String?,
        glucoseLow: json['glucose_low'] as int?,
        glucoseHigh: json['glucose_high'] as int?,
        systolicLimit: json['systolic_limit'] as int?,
        diastolicLimit: json['diastolic_limit'] as int?,
        times: (json['times'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) => MeasurementTime.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  @override
  List<Object?> get props => [
    id,
    number,
    effectiveFromOn,
    time,
    weekdays,
    graceMinutes,
    glucoseContext,
    _times,
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
      kind: MeasurementKind.values.byName(json['kind'] as String),
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
    this.glucoseContext,
    this.condition,
    this.note,
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
  final String? glucoseContext;
  final String? condition;
  final String? note;
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
        kind: MeasurementKind.values.byName(json['kind'] as String),
        outcome: json['outcome'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        measuredAt: json['measured_at'] == null
            ? null
            : DateTime.parse(json['measured_at'] as String),
        valueOne: json['value_one'] as int?,
        valueTwo: json['value_two'] as int?,
        glucoseContext: json['glucose_context'] as String?,
        condition: json['condition'] as String?,
        note: json['note'] as String?,
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
            (json['recorded_by'] as Map<String, dynamic>?)?['name']
                as String?,
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
    glucoseContext,
    condition,
    note,
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
    this.glucoseContext,
    this.record,
  });

  final String planId;
  final String versionId;
  final MeasurementKind kind;
  final DateTime scheduledOn;
  final String time;
  final DateTime deadlineAt;
  final MeasurementStatus status;
  final String? glucoseContext;
  final MeasurementReading? record;

  factory MeasurementOccurrence.fromJson(Map<String, dynamic> json) =>
      MeasurementOccurrence(
        planId: json['plan_id'] as String,
        versionId: json['version_id'] as String,
        kind: MeasurementKind.values.byName(json['kind'] as String),
        scheduledOn: DateTime.parse(json['scheduled_on'] as String),
        time: json['time_of_day'] as String,
        deadlineAt: DateTime.parse(json['deadline_at'] as String),
        status: MeasurementStatus.values.byName(
          (json['status'] as String).replaceAllMapped(
            RegExp(r'_([a-z])'),
            (match) => match[1]!.toUpperCase(),
          ),
        ),
        glucoseContext: json['glucose_context'] as String?,
        record: json['record'] == null
            ? null
            : MeasurementReading.fromJson(
                json['record'] as Map<String, dynamic>,
              ),
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
    glucoseContext,
    record,
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
  /// server without several times too; more are sent as `times`.
  Map<String, dynamic> toJson({int? expectedVersion}) => {
    'kind': kind.name,
    if (times.length == 1) ...times.single.toJson() else
      'times': [for (final MeasurementTime item in times) item.toJson()],
    'weekdays': weekdays,
    'starts_on': _date(startsOn),
    'effective_from_on': ?(expectedVersion == null ? null : _date(startsOn)),
    'grace_minutes': graceMinutes,
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
    this.glucoseContext,
    this.condition,
    this.note,
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
  final String? glucoseContext;
  final String? condition;
  final String? note;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'outcome': outcome,
    'measured_at': measuredAt?.toUtc().toIso8601String(),
    'value_one': valueOne,
    'value_two': valueTwo,
    'glucose_context': glucoseContext,
    'condition': condition,
    'note': note,
    'glucose_low': glucoseLow,
    'glucose_high': glucoseHigh,
    'systolic_limit': systolicLimit,
    'diastolic_limit': diastolicLimit,
  };
}

String measurementDate(DateTime value) => _date(value);

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
