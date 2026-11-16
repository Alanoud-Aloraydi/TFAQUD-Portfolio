import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The pencil on a medicine's card, for a member who may change the plan.
/// Null for a plan that has ended or was stopped: there is nothing left to
/// change, and its card stays as the record of it.
Widget? medicationEditButton(
  BuildContext context, {
  required String circleId,
  required MedicationPlan plan,
  required bool canManage,
  required DateTime today,
}) {
  final PlanStatus status = plan.statusOn(today);
  final bool editable =
      canManage &&
      (status == PlanStatus.active || status == PlanStatus.scheduled);
  if (!editable) return null;
  return PlanEditButton(
    onPressed: () =>
        context.push<bool>(Routes.editMedication(circleId, plan.id)),
    tooltip: context.tr('medications.edit_title'),
  );
}
