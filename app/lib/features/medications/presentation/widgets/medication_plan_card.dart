import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/dosage_form.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One medicine as a plan card: its photo or pill, name, form and status
/// with the pencil, a change waiting for later, and «تفاصيل الدواء» with its
/// schedules and the rest. A plan in use or yet to start can be edited and
/// stopped.
class MedicationPlanCard extends StatelessWidget {
  const MedicationPlanCard({
    super.key,
    required this.circleId,
    required this.plan,
    required this.canManage,
  });

  final String circleId;
  final MedicationPlan plan;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    final today = PatientClockScope.of(context).today();
    return PlanItemCard(
      leading: MedicationLeading(circleId: circleId, planId: plan.id),
      title: DoseStrengthLine(
        name: version.name,
        strengthValue: version.strengthValue,
        strengthUnit: version.strengthUnit,
      ),
      subtitle: MedicationFormText(version.dosageForm),
      edit: medicationEditButton(
        context,
        circleId: circleId,
        plan: plan,
        canManage: canManage,
        today: today,
      ),
      status: PlanStatusBadge(plan.statusOn(today)),
      body: medicationPlanCardBody(circleId: circleId, plan: plan),
      start: formatMedicationPeriod(
        context,
        version.startsOn,
        version.endsOn,
        today: today,
      ),
      detailsLabel: context.tr('medications.details'),
      details: medicationPlanDetails(
        context,
        circleId: circleId,
        plan: plan,
        canManage: canManage,
        today: today,
      ),
    );
  }
}

/// The form of a medicine (tablets, syrup, …) in small words under its name.
class MedicationFormText extends StatelessWidget {
  const MedicationFormText(this.form, {super.key});

  final DosageForm form;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr('medications.form.${form.name}'),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

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
