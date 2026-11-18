import 'dart:ui';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_hit.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
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
