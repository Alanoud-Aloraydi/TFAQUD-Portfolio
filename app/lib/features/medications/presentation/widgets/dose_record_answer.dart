import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/care_voice.dart';
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
