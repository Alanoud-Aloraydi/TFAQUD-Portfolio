import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_painter.dart';
import 'package:flutter/material.dart';

/// The drawing of a [chart], [height] high, spread and scrolled by [view].
class MeasurementChartCanvas extends StatelessWidget {
  const MeasurementChartCanvas({
    super.key,
    required this.chart,
    required this.view,
    required this.height,
  });

  final MeasurementChart chart;
  final ChartZoom view;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: MeasurementPainter(
          chart.kind,
          chart.readings,
          chart.month,
          chart.target,
          PatientClockScope.of(context),
          view: view,
        ),
      ),
    );
  }
}
