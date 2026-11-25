import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

/// The change that waits for its first day, on the medicine's own page, in
/// the same card as each step of «سجل التعديلات»: the day it takes over,
/// what that means for the past doses, the medicine as it will be (the
/// schedule of now crossed out), and «إلغاء التعديل» for a member who may
/// drop it.
class MedicationPendingRevision extends StatelessWidget {
  const MedicationPendingRevision({
    super.key,
    required this.plan,
    required this.circleId,
    required this.canManage,
    required this.onCancel,
  });

  final MedicationPlan plan;
  final String circleId;
  final bool canManage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final MedicationVersion pending = plan.pendingVersion!;
    return MedicationVersionCard(
      title: context.tr(
        'medications.pending_revision',
        args: <String>[formatMedicationDate(context, pending.effectiveFromOn)],
      ),
      note: CareVoice.tr(context, circleId, 'medications.effective_hint'),
      version: pending,
      previous: plan.version,
      action: canManage
          ? TextButton(
              onPressed: onCancel,
              child: Text(context.tr('medications.cancel_pending')),
            )
          : null,
    );
  }
}
