import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A month [card]'s readings as the chart or, with [calendar], the
/// calendar, the one fading into the other.
class MeasurementMonthView extends StatelessWidget {
  const MeasurementMonthView({
    super.key,
    required this.card,
    required this.calendar,
  });

  final MeasurementChartCard card;
  final bool calendar;

  @override
  Widget build(BuildContext context) {
    final ChartTarget target = ChartTarget.of(
      kind: card.kind,
      readings: card.readings,
    );
    return AnimatedSwitcher(
      duration: AppMotion.branchEnterDuration,
      reverseDuration: AppMotion.branchExitDuration,
      switchInCurve: AppMotion.branchEnter,
      switchOutCurve: AppMotion.easeIn,
      child: KeyedSubtree(
        key: ValueKey(calendar),
        child: calendar
            ? MeasurementCalendar(
                readings: card.readings,
                month: card.month,
                circleId: card.circleId,
              )
            : MeasurementChart(
                kind: card.kind,
                readings: card.readings,
                month: card.month,
                circleId: card.circleId,
                target: target,
              ),
      ),
    );
  }
}

/// The kind of reading a month card is about, and its [latest] value.
class MeasurementChartCardHeader extends StatelessWidget {
  const MeasurementChartCardHeader({
    super.key,
    required this.kind,
    required this.latest,
  });

  final MeasurementKind kind;
  final MeasurementReading? latest;

  @override
  Widget build(BuildContext context) {
    final bool glucose = kind == MeasurementKind.glucose;
    return Row(
      children: <Widget>[
        Icon(glucose ? CupertinoIcons.drop : CupertinoIcons.heart),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.tr(glucose ? 'measurements.glucose' : 'measurements.bp'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (latest case final MeasurementReading reading)
          ReadingValue(reading: reading),
      ],
    );
  }
}
