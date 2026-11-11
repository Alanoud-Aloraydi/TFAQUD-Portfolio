import 'dart:ui' as ui;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter/material.dart';

/// Draws a month of readings: glucose columns or blood pressure capsules,
/// over the target band.
class MeasurementPainter extends CustomPainter {
  MeasurementPainter(
    this.kind,
    this.readings,
    this.month,
    this.targetLow,
    this.targetHigh,
    this.clock,
  );

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final DateTime month;
  final int? targetLow;
  final int? targetHigh;

  /// The patient's clock: a reading falls on its day where they live.
  final PatientClock clock;

  @override
  void paint(Canvas canvas, Size size) {
    final ChartScale scale = ChartScale.of(size, month, readings, targetHigh);
    _target(canvas, scale);
    _grid(canvas, scale);
    _bars(canvas, scale);
    for (final int day in <int>[1, 8, 15, 22, 29]) {
      if (day > scale.days) continue;
      _label(canvas, '$day', Offset(scale.x(day) - 3, size.height - 9));
    }
  }

  void _target(Canvas canvas, ChartScale scale) {
    final int? low = targetLow;
    final int? high = targetHigh;
    if (low == null || high == null) return;
    final double right = scale.size.width - ChartScale.labelWidth;
    if (kind == MeasurementKind.glucose) {
      canvas.drawRect(
        Rect.fromLTRB(ChartScale.chartLeft, scale.y(high), right, scale.y(low)),
        Paint()..color = AppSemanticColors.selectedSurface,
      );
      return;
    }
    for (final int limit in <int>[low, high]) {
      canvas.drawLine(
        Offset(ChartScale.chartLeft, scale.y(limit)),
        Offset(right, scale.y(limit)),
        Paint()
          ..color = AppSemanticColors.statusSuccess
          ..strokeWidth = 1.5,
      );
    }
  }

  void _grid(Canvas canvas, ChartScale scale) {
    final double right = scale.size.width - ChartScale.labelWidth;
    for (final int tick in <int>[
      0,
      (scale.topValue / 2).round(),
      scale.topValue.round(),
    ]) {
      canvas.drawLine(
        Offset(ChartScale.chartLeft, scale.y(tick)),
        Offset(right, scale.y(tick)),
        Paint()..color = AppSemanticColors.borderSubtle,
      );
      _label(canvas, '$tick', Offset(right + 3, scale.y(tick)));
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
        final num second = kind == MeasurementKind.glucose
            ? 0
            : reading.valueTwo!;
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
                ? AppSemanticColors.statusWarning
                : AppSemanticColors.textPrimary,
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
      oldDelegate.targetLow != targetLow ||
      oldDelegate.targetHigh != targetHigh ||
      oldDelegate.clock != clock;
}
