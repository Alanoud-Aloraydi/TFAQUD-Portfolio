import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/skip_reason_sheet.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A refused answer's message ([messageKey]), wherever the controls are.
/// [context] must still be mounted.
void showDoseRefusal(BuildContext context, String? messageKey) {
  if (messageKey == null) return;
  AppToast.show(context, messageKey, kind: ToastKind.error);
}

/// What the person sees once the record is written: the refusal when the
/// server turned it down, otherwise the confirmation that it was saved —
/// a recorded dose changes little on screen, so silence would leave the
/// person unsure whether it reached the record.
void showDoseAnswer(
  BuildContext context,
  String? messageKey,
  String? circleId, {
  required bool taken,
}) {
  if (messageKey != null) return showDoseRefusal(context, messageKey);
  AppToast.showText(
    ScaffoldMessenger.of(context),
    CareVoice.tr(
      context,
      circleId,
      taken ? 'medications.taken_status' : 'medications.skipped_status',
    ),
  );
}

/// Asks why the dose is skipped (optional) with the app's one skip sheet,
/// and returns the skipped record to save; null when the sheet is closed.
Future<DoseRecordDraft?> selectSkippedDose(BuildContext context) async {
  final SkipReasonChoice? choice = await showSkipReasonSheet(
    context,
    title: context.tr('medications.skip_title'),
    message: context.tr('medications.skip_reason_optional'),
    reasons: <SkipReasonOption>[
      for (final DoseSkipReason reason in DoseSkipReason.values)
        SkipReasonOption(
          reason.apiValue,
          context.tr('medications.skip_reason.${reason.name}'),
        ),
    ],
    noteLabel: context.tr('medications.skip_reason_note'),
    confirmLabel: context.tr('medications.skip_confirm'),
  );
  if (choice == null) return null;
  return DoseRecordDraft(
    outcome: DoseOutcome.skipped,
    skipReasonCode: choice.code,
    skipReasonNote: choice.note,
  );
}
