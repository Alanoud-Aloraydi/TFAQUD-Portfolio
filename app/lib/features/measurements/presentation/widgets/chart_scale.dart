import 'dart:math' as math;
import 'dart:ui';

import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';

export 'package:app/features/measurements/presentation/widgets/readings_by_day.dart';

/// The geometry of a month chart, shared by what draws it and what answers
/// a tap, so the two can never disagree about where a bar is. Days run from
/// the right edge, as an Arabic page reads.
class ChartScale {
  ChartScale({
    required this.size,
    required this.days,
    required this.topValue,
    this.bottomValue = 0,
    this.step = 0,
    this.view = ChartZoom.none,
  });

  factory ChartScale.of(
    Size size,
    DateTime month,
    List<MeasurementReading> readings,
    int? targetHigh, {
    int? targetLow,
    MeasurementKind kind = MeasurementKind.glucose,
    ChartZoom view = ChartZoom.none,
  }) {
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
    return ChartScale(
      size: size,
      days: DateTime(month.year, month.month + 1, 0).day,
      topValue: top,
      bottomValue: values.isEmpty && targetHigh == null ? 0 : bottom,
      step: step,
      view: view,
    );
  }

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

  static const double labelWidth = 29;
  static const double chartLeft = 4;
  static const double chartTop = 16;
  static const double bottomPad = 24;

  final Size size;
  final int days;
  final double topValue;

  /// The distance between two lines of the axis.
  final double step;

  /// Where the axis starts: readings live well above zero.
  final double bottomValue;

  /// How far the days are spread, and scrolled.
  final ChartZoom view;

  double get chartBottom => size.height - bottomPad;
  double get right => size.width - labelWidth;
  double get slot => plotWidth(size.width) * view.zoom / days;

  /// The width the days share at zoom 1, in a chart [width] wide.
  static double plotWidth(double width) => width - labelWidth - chartLeft;

  /// The days labelled: all once there is room, else every other day,
  /// else the start of each week.
  List<int> get labelDays {
    final int every = slot >= 24 ? 1 : (slot >= 13 ? 2 : 7);
    return <int>[for (int day = 1; day <= days; day += every) day];
  }

  double y(num value) =>
      chartBottom -
      ((value.clamp(bottomValue, topValue) - bottomValue) /
              (topValue - bottomValue)) *
          (chartBottom - chartTop);

  /// The three to five lines the chart draws and labels.
  List<int> get ticks {
    final double gap = step > 0 ? step : (topValue - bottomValue) / 3;
    return <int>[
      for (double at = bottomValue; at <= topValue + .01; at += gap) at.round(),
    ];
  }

  double x(int day) => right - (day - .5) * slot + view.shift;

  /// The width of one bar when [count] readings share a day: thin enough
  /// that four on a nine-point day do not overlap into one blob.
  double barWidth(int count) => math.min(9, math.max(2, slot / count - 1));

  /// The distance between the centres of bars that share a day: side by
  /// side at zoom 1, apart once a zoom gives the day room to tap each.
  double barStep(int count) => math.max(
    math.min(barWidth(count) + 1, math.max(3, slot / count)),
    slot * .6 / count,
  );

  /// The centre of the [index]th of [count] bars on [day], the earliest at
  /// the right: time runs right to left inside a day too.
  double center(int day, int index, int count) =>
      x(day) - (index - (count - 1) / 2) * barStep(count);
}
