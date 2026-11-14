import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_actions.dart';
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
  required bool canStop,
}) {
  final MedicationVersion version = plan.version;
  return <Widget>[
    PlanFactGroup(
      title: context.tr('plan_details.schedule'),
      children: <Widget>[
        for (final schedule in version.schedules)
          MedicationScheduleLine(schedule: schedule),
      ],
    ),
    PlanFactGroup(
      title: context.tr('plan_details.about_medicine'),
      children: <Widget>[
        if (version.reason case final String reason)
          PlanFact(
            icon: AppIcons.firstAid,
            label: context.tr('medications.reason'),
            value: reason,
          ),
        if (version.instructions case final String instructions)
          PlanFact(
            icon: AppIcons.info,
            label: context.tr('medications.instructions'),
            value: instructions,
          ),
        PlanFact(
          icon: AppIcons.hourglass,
          label: context.tr('medications.missed_after'),
          value: arabicCount(
            context,
            ArabicCount.minutes,
            version.missedAfterMinutes,
          ),
        ),
      ],
    ),
    if (plan.createdByName != null || plan.lastEditedByName != null)
      PlanFactGroup(
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
      ),
    if (canStop)
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppItemCard.touch),
            foregroundColor: AppSemanticColors.statusError,
          ),
          onPressed: () => discontinueMedication(context, plan),
          child: Text(context.tr('medications.discontinue')),
        ),
      ),
  ];
}
