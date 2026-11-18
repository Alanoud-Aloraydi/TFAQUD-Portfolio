import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الجدول» of a measurement plan: each time in bold with its meal state,
/// and the days.
class MeasurementPlanSchedule extends StatelessWidget {
  const MeasurementPlanSchedule({super.key, required this.version});

  final MeasurementVersion version;

  @override
  Widget build(BuildContext context) {
    return PlanFactGroup(
      title: context.tr('plan_details.schedule'),
      children: <Widget>[
        for (final MeasurementTime reading in version.readingTimes)
          PlanFact(
            icon: ScheduleIcons.clock,
            value: clockText(reading.time),
            trailing: reading.measurementState == null
                ? null
                : StatusBadge(
                    text: context.tr(
                      'measurements.condition.${reading.measurementState}',
                    ),
                    tone: StatusTone.neutral,
                  ),
          ),
        PlanFact(
          icon: ScheduleIcons.calendar,
          label: context.tr('measurements.days'),
          below: WeekdayStrip(days: version.weekdays),
        ),
      ],
    );
  }
}
