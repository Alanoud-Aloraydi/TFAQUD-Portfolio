import 'dart:ui';

import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axis.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';

export 'package:app/features/measurements/presentation/widgets/chart_scale_geometry.dart';
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
    final ChartAxis axis = ChartAxis.fit(readings, targetHigh, targetLow, kind);
    return ChartScale(
      size: size,
      days: DateTime(month.year, month.month + 1, 0).day,
      topValue: axis.top,
      bottomValue: axis.bottom,
      step: axis.step,
      view: view,
    );
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

  /// The width the days share at zoom 1, in a chart [width] wide.
  static double plotWidth(double width) => width - labelWidth - chartLeft;
}
