import 'dart:ui' as ui;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/chart_colors.dart';
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
    _target(canvas, scale);
    _grid(canvas, scale);
    // Zoomed in, the days out of view stay out, off the axis labels.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(ChartScale.chartLeft, 0, scale.right, size.height),
    );
    if (kind == MeasurementKind.glucose) {
      _line(canvas, scale);
    } else {
      _bars(canvas, scale);
    }
    for (final int day in scale.labelDays) {
      _label(canvas, '$day', Offset(scale.x(day) - 3, size.height - 9));
    }
    canvas.restore();
  }

  /// The normal bands, the outer first so an inner one shows over it.
  void _target(Canvas canvas, ChartScale scale) {
    for (final ChartBand band in target.bands) {
      canvas.drawRect(
        Rect.fromLTRB(
          ChartScale.chartLeft,
          scale.y(band.high),
          scale.right,
          scale.y(band.low),
        ),
        Paint()..color = ChartColors.band(band),
      );
    }
  }

  void _grid(Canvas canvas, ChartScale scale) {
    for (final int tick in scale.ticks) {
      canvas.drawLine(
        Offset(ChartScale.chartLeft, scale.y(tick)),
        Offset(scale.right, scale.y(tick)),
        Paint()..color = AppSemanticColors.borderSubtle,
      );
      _label(canvas, '$tick', Offset(scale.right + 3, scale.y(tick)));
    }
  }

  /// Glucose over the month: every reading a dot, the dots of the month
  /// joined, so a rise or a fall is the shape of the line. Out of range
  /// dots keep the warning colour.
  void _line(Canvas canvas, ChartScale scale) {
    final List<(Offset, bool)> points = <(Offset, bool)>[];
    final Map<int, List<MeasurementReading>> byDay = readingsByDay(
      readings,
      month,
      clock,
    );
    final List<int> days = byDay.keys.toList()..sort();
    for (final int day in days) {
      final List<MeasurementReading> ofDay = byDay[day]!;
      for (int index = 0; index < ofDay.length; index++) {
        final MeasurementReading reading = ofDay[index];
        points.add((
          Offset(
            scale.center(day, index, ofDay.length),
            scale.y(reading.valueOne!),
          ),
          reading.outsideTarget == true,
        ));
      }
    }
    if (points.length > 1) {
      final Path path = Path()..moveTo(points.first.$1.dx, points.first.$1.dy);
      for (final (Offset at, _) in points.skip(1)) {
        path.lineTo(at.dx, at.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = ChartColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final (Offset at, bool outside) in points) {
      canvas.drawCircle(
        at,
        4,
        Paint()..color = outside ? ChartColors.outside : ChartColors.reading,
      );
    }
  }

  void _bars(Canvas canvas, ChartScale scale) {
    final Map<int, List<MeasurementReading>> byDay = readingsByDay(
      readings,
      month,
      clock,
    );
    for (final MapEntry<int, List<MeasurementReading>> entry in byDay.entries) {
      final double width = scale.barWidth(entry.value.length);
      for (int index = 0; index < entry.value.length; index++) {
        final MeasurementReading reading = entry.value[index];
        final double center = scale.center(
          entry.key,
          index,
          entry.value.length,
        );
        final num second = reading.valueTwo!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              center - width / 2,
              scale.y(reading.valueOne!),
              center + width / 2,
              scale.y(second),
            ),
            Radius.circular(width / 2),
          ),
          Paint()
            ..color = reading.outsideTarget == true
                ? ChartColors.outside
                : ChartColors.reading,
        );
      }
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          color: AppSemanticColors.textSupporting,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(at.dx, at.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) =>
      oldDelegate.readings != readings ||
      oldDelegate.month != month ||
      oldDelegate.target != target ||
      oldDelegate.clock != clock ||
      oldDelegate.view != view;
}
