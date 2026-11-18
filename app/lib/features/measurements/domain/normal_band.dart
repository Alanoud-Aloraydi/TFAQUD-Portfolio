import 'package:app/features/measurements/domain/measurement_level.dart';
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
