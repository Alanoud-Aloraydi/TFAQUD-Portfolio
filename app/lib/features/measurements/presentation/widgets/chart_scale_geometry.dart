import 'dart:math' as math;

import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';

/// Where a value, a day and a bar fall on a month chart.
extension ChartScaleGeometry on ChartScale {
  double get chartBottom => size.height - ChartScale.bottomPad;
  double get right => size.width - ChartScale.labelWidth;
  double get slot => ChartScale.plotWidth(size.width) * view.zoom / days;

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
          (chartBottom - ChartScale.chartTop);

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
