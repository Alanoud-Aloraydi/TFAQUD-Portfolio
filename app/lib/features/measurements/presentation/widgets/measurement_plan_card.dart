import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_bar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// The pencil of a measurement plan card, to its form; none for someone who
/// cannot manage the plans.
EditAction? measurementPlanEditAction(
  BuildContext context, {
  required bool canManage,
  required String circleId,
  required String planId,
}) => canManage
    ? EditAction.pen(
        onPressed: () =>
            context.push(CareItemRoutes.editMeasurement(circleId, planId)),
        tooltip: context.tr('measurements.edit_plan'),
      )
    : null;

/// What a measurement plan card opens, in groups: «الجدول» (each time in
/// bold with its meal state, and the days), «المعدل الطبيعي» of its
/// readings, «عن القياس» (when a reading counts as missed), «الأشخاص» (who
/// added and last changed it, with their pictures), and «إيقاف الخطة» in
/// red for a manager.
List<Widget> measurementPlanDetails(
  BuildContext context, {
  required String circleId,
  required MeasurementPlan plan,
  required bool canManage,
}) {
  final MeasurementVersion version = plan.version;
  return <Widget>[
    MeasurementPlanSchedule(version: version),
    MeasurementPlanRanges(plan: plan),
    PlanFactGroup(
      title: context.tr('plan_details.about_measurement'),
      children: <Widget>[
        PlanFact(
          icon: PeopleIcons.hourglass,
          label: context.tr('measurements.missed_after'),
          value: arabicCount(
            context,
            ArabicCount.minutes,
            version.missedAfterMinutes,
          ),
        ),
      ],
    ),
    if (plan.createdByName != null || plan.lastEditedByName != null)
      MeasurementPlanPeople(plan: plan, circleId: circleId),
    if (canManage)
      StopButton(
        label: context.tr('measurements.stop_plan'),
        onPressed: () => stopMeasurementPlan(context, plan),
      ),
  ];
}

/// Asks to confirm, then stops [plan] and says how it went. [context] must
/// stay mounted while the answer is awaited.
Future<void> stopMeasurementPlan(
  BuildContext context,
  MeasurementPlan plan,
) async {
  final bool? confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('measurements.stop_plan'),
    message: context.tr('measurements.stop_confirm'),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('measurements.stop_plan'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final String? errorKey = await context.read<MeasurementPlansCubit>().stop(
    plan,
  );
  if (!context.mounted) return;
  if (errorKey == null) {
    AppToast.show(context, 'toast.measurement_plan_stopped');
    return;
  }
  AppToast.show(context, errorKey, kind: ToastKind.error);
}

/// «المعدل الطبيعي» of a plan's readings, from the section's
/// [MeasurementRangesCubit]: one line per range (glucose: per meal state
/// its times use). Nothing while the ranges load or fail; the reading
/// sheet shows them too.
class MeasurementPlanRanges extends StatelessWidget {
  const MeasurementPlanRanges({super.key, required this.plan});

  final MeasurementPlan plan;

  @override
  Widget build(BuildContext context) {
    final NormalRanges? ranges = context
        .watch<MeasurementRangesCubit>()
        .state
        .ranges;
    if (ranges == null) return const SizedBox.shrink();
    final MeasurementKind kind = plan.kind;
    final List<NormalRange> shown = kind == MeasurementKind.bp
        ? <NormalRange>[?ranges.of(kind)]
        : <NormalRange>[
            for (final String group in <String>{
              for (final MeasurementTime item in plan.version.readingTimes)
                normalRangeState(item.measurementState),
            })
              ?ranges.of(kind, group),
          ];
    return PlanFactGroup(
      title: context.tr('measurements.normal_range'),
      children: <Widget>[
        for (final NormalRange range in shown)
          PlanFact(
            icon: kind == MeasurementKind.bp
                ? CareIcons.heartbeat
                : CareIcons.drop,
            label: normalRangeCaption(
              context,
              kind,
              range.profile,
              range.state,
            ),
            value:
                '${normalBandText(context, kind, range.normal)} '
                '${context.tr(kind == MeasurementKind.bp ? 'measurements.bp_unit' : 'measurements.glucose_unit')}',
          ),
      ],
    );
  }
}

/// «الجدول» of a measurement plan: each time in bold with its meal state,
/// and the days.
class MeasurementPlanSchedule extends StatelessWidget {
  const MeasurementPlanSchedule({super.key, required this.version});

  final MeasurementVersion version;

  @override
  Widget build(BuildContext context) {
    return PlanFactGroup(
      title: context.tr('plan_details.schedule'),
      children: <Widget>[
        for (final MeasurementTime reading in version.readingTimes)
          PlanFact(
            icon: ScheduleIcons.clock,
            value: clockText(reading.time),
            trailing: reading.measurementState == null
                ? null
                : StatusBadge(
                    text: context.tr(
                      'measurements.condition.${reading.measurementState}',
                    ),
                    tone: StatusTone.neutral,
                  ),
          ),
        PlanFact(
          icon: ScheduleIcons.calendar,
          label: context.tr('measurements.days'),
          below: WeekdayStrip(days: version.weekdays),
        ),
      ],
    );
  }
}
