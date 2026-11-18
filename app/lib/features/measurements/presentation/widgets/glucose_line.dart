import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_colors.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter/material.dart';

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
