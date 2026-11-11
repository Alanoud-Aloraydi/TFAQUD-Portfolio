import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the colours of a month chart mean.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.kind, required this.hasTarget});

  final MeasurementKind kind;
  final bool hasTarget;

  @override
  Widget build(BuildContext context) {
    final bool glucose = kind == MeasurementKind.glucose;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        _ChartKey(
          AppSemanticColors.textPrimary,
          context.tr('measurements.chart_legend_reading'),
        ),
        _ChartKey(
          AppSemanticColors.statusWarning,
          context.tr('measurements.chart_legend_outside'),
        ),
        if (hasTarget)
          _ChartKey(
            glucose
                ? AppSemanticColors.selectedSurface
                : AppSemanticColors.statusSuccess,
            context.tr(
              glucose
                  ? 'measurements.chart_legend_glucose_target'
                  : 'measurements.chart_legend_bp_target',
            ),
          ),
      ],
    );
  }
}

class _ChartKey extends StatelessWidget {
  const _ChartKey(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: const SizedBox(width: 12, height: 5),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
