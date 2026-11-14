import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

/// Where a reading falls in its normal range. The server judges every
/// reading by fixed ranges (by meal state and the patient's conditions in
/// the medical file); the app shows the same four levels.
enum MeasurementLevel {
  /// Below the normal range.
  low,
  normal,

  /// Above normal, not high yet: «أعلى من الطبيعي» / «طبيعي مرتفع».
  elevated,
  high;

  /// `low`, `normal`, `elevated` or `high` as the server sends it; null for
  /// a skip or a value this app does not know.
  static MeasurementLevel? fromWire(Object? value) =>
      MeasurementLevel.values.asNameMap()[value];
}

/// One level of a range and its values, glucose or blood pressure. A null
/// end has no limit: «أقل من 70», «126 فأكثر».
class NormalBand extends Equatable {
  const NormalBand({
    required this.level,
    this.glucoseLow,
    this.glucoseHigh,
    this.systolicLow,
    this.systolicHigh,
    this.diastolicLow,
    this.diastolicHigh,
  });

  final MeasurementLevel level;
  final int? glucoseLow;
  final int? glucoseHigh;
  final int? systolicLow;
  final int? systolicHigh;
  final int? diastolicLow;
  final int? diastolicHigh;

  factory NormalBand.fromJson(
    Map<String, dynamic> json, {
    MeasurementLevel? level,
  }) => NormalBand(
    level:
        level ??
        MeasurementLevel.fromWire(json['level']) ??
        MeasurementLevel.normal,
    glucoseLow: json['glucose_low'] as int?,
    glucoseHigh: json['glucose_high'] as int?,
    systolicLow: json['systolic_low'] as int?,
    systolicHigh: json['systolic_high'] as int?,
    diastolicLow: json['diastolic_low'] as int?,
    diastolicHigh: json['diastolic_high'] as int?,
  );

  @override
  List<Object?> get props => [
    level,
    glucoseLow,
    glucoseHigh,
    systolicLow,
    systolicHigh,
    diastolicLow,
    diastolicHigh,
  ];
}

/// The range one reading is judged by: its table ([profile]: `general`,
/// `diabetes` or `hypertension`), its meal state ([state]: `fasting` or
/// `after_meal` for glucose, null for blood pressure) and its normal band.
class ReadingRange extends Equatable {
  const ReadingRange({required this.profile, required this.normal, this.state});

  final String profile;
  final String? state;
  final NormalBand normal;

  /// The `normal_range` of a reading; null for a skip, or from a server
  /// before fixed ranges.
  static ReadingRange? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return ReadingRange(
      profile: value['profile'] as String,
      state: value['state'] as String?,
      normal: NormalBand.fromJson(value, level: MeasurementLevel.normal),
    );
  }

  @override
  List<Object?> get props => [profile, state, normal];
}

/// One kind's range with its four bands, low first.
class NormalRange extends Equatable {
  const NormalRange({
    required this.kind,
    required this.profile,
    required this.bands,
    this.state,
  });

  final MeasurementKind kind;
  final String profile;
  final String? state;
  final List<NormalBand> bands;

  /// The band of [level].
  NormalBand band(MeasurementLevel level) =>
      bands.firstWhere((band) => band.level == level);

  NormalBand get normal => band(MeasurementLevel.normal);

  /// The level of a value, as the server judges it: the worse number of a
  /// blood pressure decides, and high wins over low.
  MeasurementLevel levelOf(int value, [int? diastolic]) {
    if (kind == MeasurementKind.glucose) {
      for (final NormalBand item in bands) {
        if ((item.glucoseHigh ?? value) >= value) return item.level;
      }
      return MeasurementLevel.high;
    }
    final NormalBand high = band(MeasurementLevel.high);
    final NormalBand low = band(MeasurementLevel.low);
    final NormalBand normal = this.normal;
    final int second = diastolic ?? 0;
    if (value >= high.systolicLow! || second >= high.diastolicLow!) {
      return MeasurementLevel.high;
    }
    if (value <= low.systolicHigh! || second <= low.diastolicHigh!) {
      return MeasurementLevel.low;
    }
    if (value > normal.systolicHigh! || second > normal.diastolicHigh!) {
      return MeasurementLevel.elevated;
    }
    return MeasurementLevel.normal;
  }

  factory NormalRange.fromJson(Map<String, dynamic> json) => NormalRange(
    kind: json['kind'] == 'blood_pressure'
        ? MeasurementKind.bp
        : MeasurementKind.glucose,
    profile: json['profile'] as String,
    state: json['state'] as String?,
    bands: [
      for (final dynamic item in json['bands'] as List<dynamic>)
        NormalBand.fromJson(item as Map<String, dynamic>),
    ],
  );

  @override
  List<Object?> get props => [kind, profile, state, bands];
}

/// Every range of one patient, and the conditions in their medical file
/// that chose them (`diabetes`, `hypertension`).
class NormalRanges extends Equatable {
  const NormalRanges({required this.conditions, required this.ranges});

  final List<String> conditions;
  final List<NormalRange> ranges;

  /// The range a reading of [kind] in meal [state] is judged by: glucose
  /// fasting or before a meal by the fasting one, any other by the one
  /// after a meal.
  NormalRange? of(MeasurementKind kind, [String? state]) {
    final String? group = kind == MeasurementKind.bp
        ? null
        : normalRangeState(state);
    return ranges
        .where((range) => range.kind == kind && range.state == group)
        .firstOrNull;
  }

  factory NormalRanges.fromJson(Map<String, dynamic> json) => NormalRanges(
    conditions: (json['conditions'] as List<dynamic>).cast<String>(),
    ranges: [
      for (final dynamic item in json['ranges'] as List<dynamic>)
        NormalRange.fromJson(item as Map<String, dynamic>),
    ],
  );

  @override
  List<Object?> get props => [conditions, ranges];
}

/// The glucose table a meal state is read from: `fasting` for fasting or
/// before a meal, else `after_meal` (after a meal, at bedtime, or none).
String normalRangeState(String? state) =>
    state == 'fasting' || state == 'before_meal' ? 'fasting' : 'after_meal';
