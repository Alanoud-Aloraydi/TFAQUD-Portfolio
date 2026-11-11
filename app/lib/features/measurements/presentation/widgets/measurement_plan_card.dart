import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_plan_status.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_details.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_target_box.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_times_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One measurement plan as a plan card: its kind and status with the
/// pencil, reading times and days, the target, a change waiting for later,
/// and «تفاصيل القياس» for who added or changed it and stopping it.
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
    final MeasurementVersion version = plan.version;
    final DateTime today = PatientClockScope.of(context).today();
    final bool glucose = plan.kind == MeasurementKind.glucose;
    final String? condition = version.readingTimes.length == 1
        ? version.readingTimes.single.measurementState
        : null;
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
      edit: canManage
          ? PlanEditButton(
              onPressed: () =>
                  context.push(Routes.editMeasurement(circleId, plan.id)),
              tooltip: context.tr('measurements.edit_plan'),
            )
          : null,
      status: PlanStatusBadge(plan.statusOn(today)),
      body: <Widget>[
        MeasurementPlanTimesBox(version: version),
        MeasurementPlanTargetBox(kind: plan.kind, version: version),
        if (plan.pendingVersion case final MeasurementVersion pending)
          PlanInfoBox(
            emphasis: true,
            child: Text(
              context.tr(
                'measurements.pending_change',
                args: <String>[_dayText(pending.effectiveFromOn)],
              ),
            ),
          ),
      ],
      start: formatStartDate(context, _startsOn(plan), today: today),
      detailsLabel: context.tr('measurements.details'),
      details: measurementPlanDetails(
        context,
        plan: plan,
        canManage: canManage,
      ),
    );
  }

  /// The first day of the plan: its earliest version's (an edit starts a
  /// later version).
  static DateTime _startsOn(MeasurementPlan plan) =>
      <MeasurementVersion>[plan.version, ...plan.history]
          .map((MeasurementVersion item) => item.effectiveFromOn)
          .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);

  /// «9/11/2026», as the plan form's «يسري التعديل من» writes it.
  static String _dayText(DateTime day) => '${day.day}/${day.month}/${day.year}';
}
