import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks to confirm, then stops [plan] and says how it went. [context] must
/// stay mounted while the answer is awaited.
Future<void> discontinueMedication(
  BuildContext context,
  MedicationPlan plan,
) async {
  final bool? confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('medications.discontinue_title'),
    message: context.tr('medications.discontinue_message'),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('medications.discontinue_confirm'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final MedicationsCubit cubit = context.read<MedicationsCubit>();
  final bool changed = await cubit.discontinue(plan);
  if (!context.mounted) return;
  if (changed) {
    AppToast.show(context, 'toast.medication_stopped');
    return;
  }
  final String? message = cubit.state.messageKey;
  if (message != null) AppToast.show(context, message, kind: ToastKind.error);
}
