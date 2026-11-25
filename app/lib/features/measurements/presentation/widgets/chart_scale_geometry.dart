import 'dart:math' as math;

import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:equatable/equatable.dart';

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

/// How far a month chart is spread across its days: [zoom] times as wide as
/// it fits (1 to [most]), moved [shift] pixels to the right so the later
/// days, on the left, come into view. Only the days spread: the dots and
/// the capsules keep their size, so zooming in pulls them apart.
class ChartZoom extends Equatable {
  const ChartZoom({this.zoom = 1, this.shift = 0});

  static const ChartZoom none = ChartZoom();

  /// Six times: a month of 31 days then shows about five at a time.
  static const double most = 6;

  /// One press of «+» or «−».
  static const double step = 1.5;

  final double zoom;
  final double shift;

  /// The view after a pinch, a drag or a button, from this one: [zoom]
  /// becomes [to], and the point [from] pixels left of the plot's right
  /// edge ends [at] pixels from it, so what is under the fingers stays
  /// under them. [width] is the plot's width at zoom 1; the view never
  /// scrolls past day 1 or the month's last day.
  ChartZoom moved({
    required double from,
    required double at,
    required double to,
    required double width,
  }) {
    final double next = to.clamp(1, most).toDouble();
    final double shifted = (from + shift) / zoom * next - at;
    return ChartZoom(
      zoom: next,
      shift: shifted.clamp(0, width * (next - 1)).toDouble(),
    );
  }

  /// [times] as wide, around the middle of a plot [plot] wide at zoom 1.
  ChartZoom zoomedBy(double times, double plot) =>
      moved(from: plot / 2, at: plot / 2, to: zoom * times, width: plot);

  @override
  List<Object?> get props => <Object?>[zoom, shift];
}
