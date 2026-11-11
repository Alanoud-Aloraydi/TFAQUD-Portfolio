import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
