import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_plan_condition.dart';
import 'package:app/features/measurements/domain/measurement_plan_start.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_details.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_edit_action.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_pending_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// One measurement plan as a plan card: its kind and status with the
/// pencil, a change waiting for later, and «تفاصيل القياس» with its times,
/// days, normal range, who added or changed it, and stopping it.
class MeasurementPlanCard extends StatelessWidget {
  const MeasurementPlanCard({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.plan,
  });

  final String circleId;
  final bool canManage;
  final MeasurementPlan plan;

  @override
  Widget build(BuildContext context) {
    final DateTime today = PatientClockScope.of(context).today();
    final bool glucose = plan.kind == MeasurementKind.glucose;
    final String? condition = plan.singleCondition;
    return PlanItemCard(
      leading: Icon(glucose ? CupertinoIcons.drop : CupertinoIcons.heart),
      title: Text(
        measurementKindTitle(context, plan.kind),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // With one reading its condition sits under the name; with several,
      // each condition is beside its time below.
      subtitle: condition == null
          ? null
          : Text(context.tr('measurements.condition.$condition')),
      edit: measurementPlanEditAction(
        context,
        canManage: canManage,
        circleId: circleId,
        planId: plan.id,
      ),
      status: PlanStatusBadge(plan.statusOn(today)),
      // The times, days and normal range are in «تفاصيل القياس», so the
      // closed card is only what tells the plans apart.
      body: <Widget>[
        if (plan.pendingVersion case final MeasurementVersion pending)
          MeasurementPlanPendingNote(pending: pending),
      ],
      start: formatStartDate(context, plan.startsOn, today: today),
      detailsLabel: context.tr('measurements.details'),
      details: measurementPlanDetails(
        context,
        circleId: circleId,
        plan: plan,
        canManage: canManage,
      ),
    );
  }
}
