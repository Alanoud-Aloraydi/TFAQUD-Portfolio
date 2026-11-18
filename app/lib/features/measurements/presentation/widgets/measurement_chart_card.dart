import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card_header.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_switch.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_month_view.dart';
import 'package:app/features/measurements/presentation/widgets/reading_count_text.dart';
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
            MeasurementChartCardHeader(
              kind: widget.kind,
              latest: widget.readings.firstOrNull,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(readingCountText(context, widget.readings)),
            const SizedBox(height: AppSpacing.sm),
            MeasurementChartSwitch(
              calendar: _calendar,
              onChanged: (value) => setState(() => _calendar = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            MeasurementMonthView(card: widget, calendar: _calendar),
          ],
        ),
      ),
    );
  }
}
