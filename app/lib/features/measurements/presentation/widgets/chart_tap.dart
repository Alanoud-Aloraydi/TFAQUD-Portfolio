import 'dart:ui';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';

/// The reading a tap [at] selects on [chart], drawn [size] big and spread
/// by [view]; null when no reading is within reach.
MeasurementReading? chartReadingTapped(
  Offset at, {
  required MeasurementChart chart,
  required Size size,
  required ChartZoom view,
  required PatientClock clock,
}) {
  final ChartScale scale = ChartScale.of(
    size,
    chart.month,
    chart.readings,
    chart.target.high,
    targetLow: chart.target.low,
    kind: chart.kind,
    view: view,
  );
  final Map<int, List<MeasurementReading>> byDay = readingsByDay(
    chart.readings,
    chart.month,
    clock,
  );
  return chartReadingAt(scale, byDay, chart.kind, at);
}

/// The reading a tap at [at] means on a month chart drawn with [scale]: the
/// nearest dot or capsule within a finger's reach, among those in view;
/// null when none is that close. [byDay] is the month's readingsByDay.
MeasurementReading? chartReadingAt(
  ChartScale scale,
  Map<int, List<MeasurementReading>> byDay,
  MeasurementKind kind,
  Offset at,
) {
  const double reachX = 22;
  const double reachY = 18;
  MeasurementReading? nearest;
  double distance = double.infinity;
  for (final MapEntry<int, List<MeasurementReading>> entry in byDay.entries) {
    for (int index = 0; index < entry.value.length; index++) {
      final MeasurementReading reading = entry.value[index];
      final double x = scale.center(entry.key, index, entry.value.length);
      // Zoomed in, a reading scrolled out of view cannot be tapped.
      if (x < ChartScale.chartLeft || x > scale.right) continue;
      final double dx = (x - at.dx).abs();
      final double dy = _verticalMiss(scale, reading, kind, at.dy);
      if (dx + dy < distance && dx <= reachX && dy <= reachY) {
        nearest = reading;
        distance = dx + dy;
      }
    }
  }
  return nearest;
}

/// How far [dy] is above or below [reading]: a glucose reading is a dot, a
/// pressure reading the capsule between its two numbers.
double _verticalMiss(
  ChartScale scale,
  MeasurementReading reading,
  MeasurementKind kind,
  double dy,
) {
  final double first = scale.y(reading.valueOne!);
  final double second = kind == MeasurementKind.glucose
      ? first
      : scale.y(reading.valueTwo!);
  final double top = first < second ? first : second;
  final double bottom = first < second ? second : first;
  return dy < top ? top - dy : (dy > bottom ? dy - bottom : 0);
}
