export 'package:app/features/measurements/domain/measurement_level.dart';
export 'package:app/features/measurements/domain/normal_band.dart';
export 'package:app/features/measurements/domain/normal_range_state.dart';
export 'package:app/features/measurements/domain/normal_ranges.dart';
export 'package:app/features/measurements/domain/reading_range.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_level.dart';
import 'package:app/features/measurements/domain/normal_band.dart';
import 'package:equatable/equatable.dart';

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
