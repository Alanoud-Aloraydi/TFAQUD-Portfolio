import 'dart:ui' as ui;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axis.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter/material.dart';

/// The readings of the month, [byDay], drawn as the [kind] is, and the days
/// under them, on a chart [size] big.
void paintChartReadings(
  Canvas canvas,
  ChartScale scale,
  Size size,
  MeasurementKind kind,
  Map<int, List<MeasurementReading>> byDay,
) {
  // Zoomed in, the days out of view stay out, off the axis labels.
  canvas.save();
  canvas.clipRect(
    Rect.fromLTRB(ChartScale.chartLeft, 0, scale.right, size.height),
  );
  if (kind == MeasurementKind.glucose) {
    paintGlucoseLine(canvas, scale, byDay);
  } else {
    paintPressureBars(canvas, scale, byDay);
  }
  paintDayAxis(canvas, scale, size);
  canvas.restore();
}

/// Blood pressure over the month: a capsule per reading, from the lower
/// number to the upper one, side by side when a day has several.
void paintPressureBars(
  Canvas canvas,
  ChartScale scale,
  Map<int, List<MeasurementReading>> byDay,
) {
  for (final MapEntry<int, List<MeasurementReading>> entry in byDay.entries) {
    final double width = scale.barWidth(entry.value.length);
    for (int index = 0; index < entry.value.length; index++) {
      final MeasurementReading reading = entry.value[index];
      final double center = scale.center(entry.key, index, entry.value.length);
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

/// The lines of the values across the chart, each labelled at the side.
void paintValueAxis(Canvas canvas, ChartScale scale) {
  for (final int tick in scale.ticks) {
    canvas.drawLine(
      Offset(ChartScale.chartLeft, scale.y(tick)),
      Offset(scale.right, scale.y(tick)),
      Paint()..color = AppSemanticColors.borderSubtle,
    );
    _label(canvas, '$tick', Offset(scale.right + 3, scale.y(tick)));
  }
}

/// The numbers of the days under a chart [size] high.
void paintDayAxis(Canvas canvas, ChartScale scale, Size size) {
  for (final int day in scale.labelDays) {
    _label(canvas, '$day', Offset(scale.x(day) - 3, size.height - 9));
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

/// Glucose over the month: every reading a dot, the dots of the month
/// joined, so a rise or a fall is the shape of the line. Out of range
/// dots keep the warning colour.
void paintGlucoseLine(
  Canvas canvas,
  ChartScale scale,
  Map<int, List<MeasurementReading>> byDay,
) {
  final List<(Offset, bool)> points = <(Offset, bool)>[];
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
