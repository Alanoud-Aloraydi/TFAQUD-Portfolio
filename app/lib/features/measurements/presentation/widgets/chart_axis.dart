import 'dart:math' as math;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:flutter/material.dart';

/// The values a month chart's axis runs over: from [bottom] to [top], its
/// lines [step] apart.
class ChartAxis {
  const ChartAxis(this.bottom, this.top, this.step);

  /// The axis that holds [readings] and the normal range of the [kind].
  factory ChartAxis.fit(
    List<MeasurementReading> readings,
    int? targetHigh,
    int? targetLow,
    MeasurementKind kind,
  ) {
    final List<int> values = <int>[
      for (final MeasurementReading reading in readings) ...<int>[
        if (reading.valueOne != null) reading.valueOne!,
        if (reading.valueTwo != null) reading.valueTwo!,
      ],
    ];
    final int highest = math.max(
      targetHigh ?? 0,
      values.fold<int>(0, math.max),
    );
    final int lowest = values.isEmpty
        ? 0
        : math.min(targetLow ?? 999, values.reduce(math.min));
    // A reading of 150 next to one of 130 has to look different, so the
    // axis holds the range of the readings, not everything down to zero.
    final (int floor, int ceiling) = switch (kind) {
      MeasurementKind.glucose => (60, 200),
      MeasurementKind.bp => (50, 160),
    };
    final (double bottom, double top, double step) = _bounds(
      math.min(floor, values.isEmpty ? floor : lowest),
      math.max(ceiling, highest),
    );
    return ChartAxis(
      values.isEmpty && targetHigh == null ? 0 : bottom,
      top,
      step,
    );
  }

  final double bottom;
  final double top;
  final double step;

  /// The axis in round numbers: the smallest step that covers [lowest] to
  /// [highest] in three to five lines, both ends on the step, so one high
  /// reading cannot widen the axis down to zero and flatten the rest.
  static (double, double, double) _bounds(int lowest, int highest) {
    const List<double> steps = <double>[5, 10, 20, 25, 50, 100, 200, 500];
    for (final double step in steps) {
      final double bottom = (lowest / step).floorToDouble() * step;
      final double top = (highest / step).ceilToDouble() * step;
      if ((top - bottom) / step <= 5) return (bottom, top, step);
    }
    final double step = steps.last;
    final double bottom = (lowest / step).floorToDouble() * step;
    return (bottom, bottom + step * 3, step);
  }
}

/// The colours of a month chart, read by what draws it and by its legend,
/// so the legend always shows the colours the chart uses.
abstract final class ChartColors {
  /// A reading in its normal range.
  static const Color reading = AppSemanticColors.chartInk;

  /// A reading outside its normal range.
  static const Color outside = AppSemanticColors.statusError;

  /// The line that joins a month of glucose readings.
  static final Color line = reading.withValues(alpha: .45);

  static const Color _band = AppSemanticColors.surfaceSuccess;
  static final Color _innerBand = AppSemanticColors.statusSuccess.withValues(
    alpha: .18,
  );

  /// The shade of a normal band; an inner one is darker so both show.
  static Color band(ChartBand band) => band.inner ? _innerBand : _band;
}
