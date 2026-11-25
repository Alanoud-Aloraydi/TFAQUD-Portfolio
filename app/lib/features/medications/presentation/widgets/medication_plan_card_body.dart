import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// What a medicine's plan card holds while it is closed: only a change that
/// waits for a later day. The times and doses are in «تفاصيل الدواء», so the
/// closed card is only what tells the medicines apart.
List<Widget> medicationPlanCardBody({
  required String circleId,
  required MedicationPlan plan,
}) => <Widget>[
  if (plan.pendingVersion case final pending?)
    MedicationPendingBox(
      circleId: circleId,
      current: plan.version,
      pending: pending,
    ),
];

/// «تعديل مجدول» on a medicine's plan card, the same card as on its own
/// page: the day it takes over, what that means for the past doses, and
/// the medicine as [pending] will have it (the schedule of [current]
/// crossed out). Dropping it is on the medicine's page.
class MedicationPendingBox extends StatelessWidget {
  const MedicationPendingBox({
    super.key,
    required this.circleId,
    required this.current,
    required this.pending,
  });

  final String circleId;
  final MedicationVersion current;
  final MedicationVersion pending;

  @override
  Widget build(BuildContext context) => MedicationVersionCard(
    title: context.tr(
      'medications.pending_revision',
      args: <String>[formatMedicationDate(context, pending.effectiveFromOn)],
    ),
    note: CareVoice.tr(context, circleId, 'medications.effective_hint'),
    version: pending,
    previous: current,
  );
}

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
  return EditAction.pen(
    onPressed: () =>
        context.push<bool>(CareItemRoutes.editMedication(circleId, plan.id)),
    tooltip: context.tr('medications.edit_title'),
  );
}
