import 'package:app/core/widgets/overlays/skip_reason_sheet.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
