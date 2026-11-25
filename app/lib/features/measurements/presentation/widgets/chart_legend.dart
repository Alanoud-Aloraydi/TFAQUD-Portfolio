import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axis.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale_geometry.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_painter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the colours of a month chart mean, in the colours it draws with
/// ([ChartColors]): a reading, one outside its range, and each band.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.target});

  final ChartTarget target;

  @override
  Widget build(BuildContext context) {
    // Blood pressure's two zones share one name.
    final Map<String, ChartBand> bands = <String, ChartBand>{
      for (final ChartBand band in target.bands) band.labelKey: band,
    };
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        ChartKey(
          ChartColors.reading,
          context.tr('measurements.chart_legend_reading'),
        ),
        ChartKey(
          ChartColors.outside,
          context.tr('measurements.chart_legend_outside'),
        ),
        for (final MapEntry<String, ChartBand> entry in bands.entries)
          ChartKey(ChartColors.band(entry.value), context.tr(entry.key)),
      ],
    );
  }
}

class ChartKey extends StatelessWidget {
  const ChartKey(this.color, this.label, {super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          // A pale band still shows its edge.
          border: Border.all(color: AppSemanticColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: const SizedBox(width: 12, height: 8),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

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
