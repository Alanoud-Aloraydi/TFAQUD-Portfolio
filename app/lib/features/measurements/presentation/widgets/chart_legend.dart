import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/presentation/widgets/chart_colors.dart';
import 'package:app/features/measurements/presentation/widgets/chart_key.dart';
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
