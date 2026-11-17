import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
