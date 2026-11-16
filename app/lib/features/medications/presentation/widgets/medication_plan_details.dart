import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_about_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_people_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a medicine's plan card opens, in groups: «الجدول» (each time in
/// bold with its dose and days), «عن الدواء» (the reason, the instructions,
/// when a dose counts as missed), «الأشخاص» (who added and last changed it,
/// with their pictures), and «إيقاف الدواء» in red while the plan can
/// still be stopped.
List<Widget> medicationPlanDetails(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
}) {
  return <Widget>[
    PlanFactGroup(
      title: context.tr('plan_details.schedule'),
      children: <Widget>[
        for (final schedule in plan.version.schedules)
          MedicationScheduleLine(schedule: schedule),
      ],
    ),
    medicationAboutGroup(context, plan.version),
    if (plan.createdByName != null || plan.lastEditedByName != null)
      medicationPeopleGroup(context, circleId: circleId, plan: plan),
  ];
}
