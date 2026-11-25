import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:equatable/equatable.dart';

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
