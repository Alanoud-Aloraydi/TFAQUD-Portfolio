import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axes.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/glucose_line.dart';
import 'package:app/features/measurements/presentation/widgets/pressure_bars.dart';
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
