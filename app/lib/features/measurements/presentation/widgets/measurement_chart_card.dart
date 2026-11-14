import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A month of one kind of reading: the latest value, the count, and a switch
/// between the chart and the calendar.
class MeasurementChartCard extends StatefulWidget {
  const MeasurementChartCard({
    super.key,
    required this.kind,
    required this.readings,
    required this.month,
    required this.circleId,
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final DateTime month;
  final String circleId;

  @override
  State<MeasurementChartCard> createState() => _MeasurementChartCardState();
}

class _MeasurementChartCardState extends State<MeasurementChartCard> {
  bool _calendar = false;

  @override
  Widget build(BuildContext context) {
    final bool glucose = widget.kind == MeasurementKind.glucose;
    final TextTheme text = Theme.of(context).textTheme;
    final MeasurementReading? latest = widget.readings.firstOrNull;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(glucose ? CupertinoIcons.drop : CupertinoIcons.heart),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr(
                      glucose ? 'measurements.glucose' : 'measurements.bp',
                    ),
                    style: text.titleMedium,
                  ),
                ),
                if (latest != null) ReadingValue(reading: latest),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(_summary(context)),
            const SizedBox(height: AppSpacing.sm),
            GlassSegmentedControl<bool>(
              segments: <bool, String>{
                false: context.tr('measurements.chart'),
                true: context.tr('measurements.calendar'),
              },
              selected: _calendar,
              onChanged: (value) => setState(() => _calendar = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            _view(),
          ],
        ),
      ),
    );
  }

  String _summary(BuildContext context) => widget.readings.isEmpty
      ? context.tr('measurements.no_readings')
      : context.tr(
          'measurements.reading_count',
          args: <String>[
            '${widget.readings.length}',
            '${widget.readings.where((r) => r.outsideTarget == true).length}',
          ],
        );

  Widget _view() {
    final ChartTarget target = ChartTarget.of(
      kind: widget.kind,
      readings: widget.readings,
    );
    return AnimatedSwitcher(
      duration: AppMotion.branchEnterDuration,
      reverseDuration: AppMotion.branchExitDuration,
      switchInCurve: AppMotion.branchEnter,
      switchOutCurve: AppMotion.easeIn,
      child: KeyedSubtree(
        key: ValueKey(_calendar),
        child: _calendar
            ? MeasurementCalendar(
                readings: widget.readings,
                month: widget.month,
                circleId: widget.circleId,
              )
            : MeasurementChart(
                kind: widget.kind,
                readings: widget.readings,
                month: widget.month,
                circleId: widget.circleId,
                targetLow: target.low,
                targetHigh: target.high,
              ),
      ),
    );
  }
}
