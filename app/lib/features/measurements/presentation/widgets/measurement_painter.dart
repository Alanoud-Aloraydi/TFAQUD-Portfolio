import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axes.dart';
import 'package:app/features/measurements/presentation/widgets/chart_bands.dart';
import 'package:app/features/measurements/presentation/widgets/chart_readings.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
import 'package:flutter/material.dart';

/// Draws a month of readings: glucose as a line of dots, blood pressure as
/// a capsule from the lower number to the upper one, over the normal bands.
/// The axis holds the range the readings live in, never down to zero.
class MeasurementPainter extends CustomPainter {
  MeasurementPainter(
    this.kind,
    this.readings,
    this.month,
    this.target,
    this.clock, {
    this.view = ChartZoom.none,
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final DateTime month;
  final ChartTarget target;

  /// The patient's clock: a reading falls on its day where they live.
  final PatientClock clock;

  /// How far the days are spread by a pinch or «+», and scrolled.
  final ChartZoom view;

  @override
  void paint(Canvas canvas, Size size) {
    final ChartScale scale = ChartScale.of(
      size,
      month,
      readings,
      target.high,
      targetLow: target.low,
      kind: kind,
      view: view,
    );
    paintChartBands(canvas, scale, target);
    paintValueAxis(canvas, scale);
    final Map<int, List<MeasurementReading>> byDay = readingsByDay(
      readings,
      month,
      clock,
    );
    paintChartReadings(canvas, scale, size, kind, byDay);
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) =>
      oldDelegate.readings != readings ||
      oldDelegate.month != month ||
      oldDelegate.target != target ||
      oldDelegate.clock != clock ||
      oldDelegate.view != view;
}
