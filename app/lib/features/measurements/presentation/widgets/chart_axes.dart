import 'dart:ui' as ui;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:flutter/material.dart';

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
