import 'package:equatable/equatable.dart';

enum MeasurementKind { glucose, bp }

enum MeasurementStatus { upcoming, due, missed, read, readLate, skipped }

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
  });

  final String id;
  final int number;
  final DateTime effectiveFromOn;
  final String time;
  final List<int> weekdays;
  final int graceMinutes;
  final String? glucoseContext;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;

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
    glucoseLow,
    glucoseHigh,
    systolicLimit,
    diastolicLimit,
  ];
}

class MeasurementPlan extends Equatable {
  const MeasurementPlan({
    required this.id,
    required this.kind,
    required this.version,
    required this.history,
    this.pendingVersion,
    this.stoppedAt,
  });

  final String id;
  final MeasurementKind kind;
  final MeasurementVersion version;
  final MeasurementVersion? pendingVersion;
  final List<MeasurementVersion> history;
  final DateTime? stoppedAt;

  factory MeasurementPlan.fromJson(Map<String, dynamic> json) =>
      MeasurementPlan(
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
      );

  @override
  List<Object?> get props => [
    id,
    kind,
    version,
    pendingVersion,
    history,
    stoppedAt,
  ];
}

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
    this.followedUpAt,
    this.scheduledOn,
    this.planVersionId,
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
  final DateTime? followedUpAt;
  final DateTime? scheduledOn;
  final String? planVersionId;

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
        followedUpAt: json['followed_up_at'] == null
            ? null
            : DateTime.parse(json['followed_up_at'] as String),
        scheduledOn: json['scheduled_on'] == null
            ? null
            : DateTime.parse(json['scheduled_on'] as String),
        planVersionId: json['plan_version_id'] as String?,
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
    followedUpAt,
    scheduledOn,
    planVersionId,
  ];
}

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

class MeasurementPlanDraft {
  const MeasurementPlanDraft({
    required this.kind,
    required this.time,
    required this.weekdays,
    required this.startsOn,
    required this.graceMinutes,
    this.glucoseContext,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLimit,
    this.diastolicLimit,
  });

  final MeasurementKind kind;
  final String time;
  final List<int> weekdays;
  final DateTime startsOn;
  final int graceMinutes;
  final String? glucoseContext;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLimit;
  final int? diastolicLimit;

  Map<String, dynamic> toJson({int? expectedVersion}) => {
    'kind': kind.name,
    'time_of_day': time,
    'weekdays': weekdays,
    'starts_on': _date(startsOn),
    'effective_from_on': ?(expectedVersion == null ? null : _date(startsOn)),
    'grace_minutes': graceMinutes,
    'glucose_context': glucoseContext,
    'glucose_low': glucoseLow,
    'glucose_high': glucoseHigh,
    'systolic_limit': systolicLimit,
    'diastolic_limit': diastolicLimit,
    'expected_version_number': ?expectedVersion,
  };
}

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
  });

  final MeasurementKind kind;
  final String outcome;
  final DateTime? measuredAt;
  final int? valueOne;
  final int? valueTwo;
  final String? glucoseContext;
  final String? condition;
  final String? note;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'outcome': outcome,
    'measured_at': measuredAt?.toUtc().toIso8601String(),
    'value_one': valueOne,
    'value_two': valueTwo,
    'glucose_context': glucoseContext,
    'condition': condition,
    'note': note,
  };
}

String measurementDate(DateTime value) => _date(value);

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
