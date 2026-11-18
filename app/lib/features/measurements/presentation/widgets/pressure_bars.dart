import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_colors.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter/material.dart';

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
