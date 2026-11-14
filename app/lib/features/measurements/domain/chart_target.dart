import 'dart:math' as math;

import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:equatable/equatable.dart';

/// One normal band a month chart shades, and the legend's name for it.
/// [inner] lies inside another band (fasting inside after a meal) and is
/// shaded darker so both show.
class ChartBand extends Equatable {
  const ChartBand(this.low, this.high, this.labelKey, {this.inner = false});

  final int low;
  final int high;
  final String labelKey;
  final bool inner;

  @override
  List<Object?> get props => [low, high, labelKey, inner];
}

/// The normal bands of a month chart, from the ranges its readings were
/// judged by (the latest reading's, if the medical file changed).
///
/// Glucose: one band, or two when the month has fasting and after-meal
/// readings, whose ranges differ; each dot is still judged by its own.
/// Blood pressure: the normal zone of the upper number and that of the
/// lower one, so a normal reading's bar starts in the lower zone and ends
/// in the upper one.
class ChartTarget extends Equatable {
  const ChartTarget(this.bands);

  final List<ChartBand> bands;

  @override
  List<Object?> get props => [bands];

  bool get isSet => bands.isNotEmpty;

  /// The lowest and highest value the bands cover, for the axis.
  int? get low => isSet ? bands.map((band) => band.low).reduce(math.min) : null;
  int? get high =>
      isSet ? bands.map((band) => band.high).reduce(math.max) : null;

  factory ChartTarget.of({
    required MeasurementKind kind,
    required List<MeasurementReading> readings,
  }) {
    final List<ReadingRange> ranges = <ReadingRange>[
      for (final MeasurementReading reading in readings)
        if (reading.range case final ReadingRange range) range,
    ];
    if (ranges.isEmpty) return const ChartTarget(<ChartBand>[]);
    if (kind == MeasurementKind.bp) {
      final NormalBand normal = ranges.first.normal;
      const String key = 'measurements.chart_legend_bp_target';
      return ChartTarget(<ChartBand>[
        ChartBand(normal.systolicLow!, normal.systolicHigh!, key),
        ChartBand(normal.diastolicLow!, normal.diastolicHigh!, key),
      ]);
    }
    final NormalBand? fasting = _first(ranges, fasting: true);
    final NormalBand? afterMeal = _first(ranges, fasting: false);
    if (fasting == null || afterMeal == null) {
      final NormalBand only = (fasting ?? afterMeal)!;
      return ChartTarget(<ChartBand>[
        ChartBand(
          only.glucoseLow!,
          only.glucoseHigh!,
          'measurements.chart_legend_glucose_target',
        ),
      ]);
    }
    return ChartTarget(<ChartBand>[
      ChartBand(
        afterMeal.glucoseLow!,
        afterMeal.glucoseHigh!,
        'measurements.chart_legend_after_meal',
      ),
      ChartBand(
        fasting.glucoseLow!,
        fasting.glucoseHigh!,
        'measurements.chart_legend_fasting',
        inner: true,
      ),
    ]);
  }

  static NormalBand? _first(
    List<ReadingRange> ranges, {
    required bool fasting,
  }) => ranges
      .where((range) => (range.state == 'fasting') == fasting)
      .firstOrNull
      ?.normal;
}
