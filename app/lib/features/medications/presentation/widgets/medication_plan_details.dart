import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/plan_detail_line.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a medicine's plan card opens: who added and last changed it, when a
/// dose counts as missed, the reason and the instructions, and «إيقاف الدواء»
/// in red while the plan can still be stopped.
List<Widget> medicationPlanDetails(
  BuildContext context, {
  required MedicationPlan plan,
  required bool canStop,
}) {
  final MedicationVersion version = plan.version;
  return <Widget>[
    if (plan.createdByName case final String name)
      PlanDetailLine(name, label: context.tr('medications.added_by')),
    if (plan.lastEditedByName case final String name
        when name != plan.createdByName)
      PlanDetailLine(name, label: context.tr('medications.last_edited_by')),
    PlanDetailLine(
      arabicCount(context, ArabicCount.minutes, version.missedAfterMinutes),
      label: context.tr('medications.missed_after'),
    ),
    if (version.reason case final String reason)
      PlanDetailLine(reason, label: context.tr('medications.reason')),
    if (version.instructions case final String instructions)
      PlanDetailLine(
        instructions,
        label: context.tr('medications.instructions'),
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
