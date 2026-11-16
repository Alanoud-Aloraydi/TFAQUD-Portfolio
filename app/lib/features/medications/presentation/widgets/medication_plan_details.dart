import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan_status.dart';
import 'package:app/features/medications/presentation/widgets/medication_about_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_people_group.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_actions.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a medicine's plan card opens, in groups: «الجدول» (each time in
/// bold with its dose and days), «عن الدواء» (the reason, the instructions,
/// when a dose counts as missed), «الأشخاص» (who added and last changed it,
/// with their pictures), and, for a member who manages medicines, «إيقاف
/// الدواء» in red while the plan runs or is still to come.
List<Widget> medicationPlanDetails(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
  required bool canManage,
  required DateTime today,
}) {
  final PlanStatus status = plan.statusOn(today);
  final bool stoppable =
      canManage &&
      (status == PlanStatus.active || status == PlanStatus.scheduled);
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
    if (stoppable)
      StopButton(
        label: context.tr('medications.discontinue'),
        onPressed: () => discontinueMedication(context, plan),
      ),
  ];
}
