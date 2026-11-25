import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_strength_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
        if (plan.version.schedules.isEmpty)
          PlanFact(
            icon: CareIcons.pill,
            value: context.tr('medications.no_schedules_line'),
          ),
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

/// «الأشخاص»: who added the medicine and who changed it last, with their
/// pictures. The last editor is left out while it is the person who added
/// it, so one name is not read twice.
Widget medicationPeopleGroup(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
}) {
  return PlanFactGroup(
    title: context.tr('plan_details.people'),
    children: <Widget>[
      if (plan.createdByName case final String name)
        PlanPersonFact(
          label: context.tr('medications.added_by'),
          name: name,
          circleId: circleId,
          accountId: plan.createdByAccountId,
          avatarCode: plan.createdByAvatarCode,
        ),
      if (plan.lastEditedByName case final String name
          when name != plan.createdByName)
        PlanPersonFact(
          label: context.tr('medications.last_edited_by'),
          name: name,
          circleId: circleId,
          accountId: plan.lastEditedByAccountId,
          avatarCode: plan.lastEditedByAvatarCode,
        ),
    ],
  );
}

/// Which plans «السجل» shows: every one, the ones still running, or the
/// ones already behind.
enum MedicationRecordFilter {
  all,
  current,
  previous;

  /// Whether [plan] belongs in the list on [today].
  bool keeps(MedicationPlan plan, DateTime today) => switch (this) {
    all => true,
    current => !plan.isPreviousOn(today),
    MedicationRecordFilter.previous => plan.isPreviousOn(today),
  };

  /// The key of its words, under `medications.filter`.
  String get labelKey => 'medications.filter.$name';
}
