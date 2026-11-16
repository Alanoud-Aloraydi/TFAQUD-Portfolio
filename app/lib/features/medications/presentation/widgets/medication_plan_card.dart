import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_edit_button.dart';
import 'package:app/features/medications/presentation/widgets/medication_leading.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_card_body.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_details.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
      subtitle: Text(
        context.tr('medications.form.${version.dosageForm.name}'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
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
      details: medicationPlanDetails(context, circleId: circleId, plan: plan),
    );
  }
}
