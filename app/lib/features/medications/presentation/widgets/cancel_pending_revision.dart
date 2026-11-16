import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Asks before dropping a change that waits for the patient, then drops it
/// and closes the medicine's page. A refused change leaves the page open
/// with the cubit's own words.
Future<void> cancelPendingRevision(
  BuildContext context,
  String circleId,
  MedicationPlan plan,
) async {
  final confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('medications.cancel_pending_title'),
    message: CareVoice.tr(
      context,
      circleId,
      'medications.cancel_pending_message',
    ),
    actions: [
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('medications.cancel_pending'),
        value: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final cubit = context.read<MedicationsCubit>();
  final changed = await cubit.cancelPending(plan);
  if (!context.mounted) return;
  if (changed) {
    AppToast.show(context, 'toast.change_canceled');
    context.pop(true);
    return;
  }
  final message = cubit.state.messageKey;
  if (message != null) {
    AppToast.show(context, message, kind: ToastKind.error);
  }
}
