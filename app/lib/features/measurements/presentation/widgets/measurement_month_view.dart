import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card.dart';
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
