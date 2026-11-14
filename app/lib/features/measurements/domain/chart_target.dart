import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';

/// The normal band a month chart draws: the one every reading of the month
/// was judged by. Readings judged by different ranges (fasting and after a
/// meal) share none, and the chart draws no band; each point still shows
/// whether it is outside its own.
class ChartTarget {
  const ChartTarget(this.low, this.high);

  /// Glucose: the lowest normal value. Blood pressure: the top of the
  /// normal diastolic.
  final int? low;

  /// Glucose: the highest normal value. Blood pressure: the top of the
  /// normal systolic.
  final int? high;

  bool get isSet => low != null && high != null;

  factory ChartTarget.of({
    required MeasurementKind kind,
    required List<MeasurementReading> readings,
  }) {
    final List<NormalBand> bands = <NormalBand>[
      for (final MeasurementReading reading in readings)
        if (reading.range case final ReadingRange range) range.normal,
    ];
    final NormalBand? first = bands.firstOrNull;
    if (first == null || bands.any((band) => band != first)) {
      return const ChartTarget(null, null);
    }
    return kind == MeasurementKind.glucose
        ? ChartTarget(first.glucoseLow, first.glucoseHigh)
        : ChartTarget(first.diastolicHigh, first.systolicHigh);
  }
}
