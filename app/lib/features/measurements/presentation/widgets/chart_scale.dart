import 'dart:ui';

import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axis.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale_geometry.dart';

export 'package:app/features/measurements/presentation/widgets/chart_scale_geometry.dart';

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
    CalendarMonth month,
    List<MeasurementReading> readings,
    int? targetHigh, {
    int? targetLow,
    MeasurementKind kind = MeasurementKind.glucose,
    ChartZoom view = ChartZoom.none,
  }) {
    final ChartAxis axis = ChartAxis.fit(readings, targetHigh, targetLow, kind);
    return ChartScale(
      size: size,
      days: month.days,
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

/// The readings of [month] grouped by their day of it (1 is its first, in
/// either calendar) where the patient lives, never the phone's zone, each
/// day in the order they were measured (the server sends the last recorded
/// first).
Map<int, List<MeasurementReading>> readingsByDay(
  List<MeasurementReading> readings,
  CalendarMonth month,
  PatientClock clock,
) {
  final Map<int, List<MeasurementReading>> byDay =
      <int, List<MeasurementReading>>{};
  for (final MeasurementReading reading in readings) {
    final DateTime? moment = reading.measuredAt;
    if (moment == null) continue;
    final int? day = month.numberOf(clock.wallTime(moment));
    if (day == null) continue;
    byDay.putIfAbsent(day, () => <MeasurementReading>[]).add(reading);
  }
  for (final List<MeasurementReading> day in byDay.values) {
    day.sort((a, b) => a.measuredAt!.compareTo(b.measuredAt!));
  }
  return byDay;
}
