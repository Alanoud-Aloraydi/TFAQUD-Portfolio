import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/presentation/widgets/chart_colors.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter/material.dart';

/// The normal bands, the outer first so an inner one shows over it.
void paintChartBands(Canvas canvas, ChartScale scale, ChartTarget target) {
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
