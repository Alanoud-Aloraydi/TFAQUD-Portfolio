import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_bar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_ranges.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
