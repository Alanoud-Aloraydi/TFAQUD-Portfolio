import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_people.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_ranges.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a measurement plan card opens, in groups: «الجدول» (each time in
/// bold with its meal state, and the days), «المعدل الطبيعي» of its
/// readings, «عن القياس» (when a reading counts as missed), «الأشخاص» (who
/// added and last changed it, with their pictures), and «إيقاف الخطة» in
/// red for a manager.
List<Widget> measurementPlanDetails(
  BuildContext context, {
  required String circleId,
  required MeasurementPlan plan,
  required bool canManage,
}) {
  final MeasurementVersion version = plan.version;
  return <Widget>[
    MeasurementPlanSchedule(version: version),
    MeasurementPlanRanges(plan: plan),
    PlanFactGroup(
      title: context.tr('plan_details.about_measurement'),
      children: <Widget>[
        PlanFact(
          icon: PeopleIcons.hourglass,
          label: context.tr('measurements.missed_after'),
          value: arabicCount(
            context,
            ArabicCount.minutes,
            version.missedAfterMinutes,
          ),
        ),
      ],
    ),
    if (plan.createdByName != null || plan.lastEditedByName != null)
      MeasurementPlanPeople(plan: plan, circleId: circleId),
    if (canManage)
      StopButton(
        label: context.tr('measurements.stop_plan'),
        onPressed: () => stopMeasurementPlan(context, plan),
      ),
  ];
}
