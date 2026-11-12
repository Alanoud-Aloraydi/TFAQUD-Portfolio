import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/overlays/skip_reason_sheet.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks when the dose of [scheduledOn] was taken and returns that moment.
/// The time picked is the patient's wall clock on that day, wherever this
/// phone is; the wheel starts at now on that clock.
///
/// [circleId] picks the words: «متى أخذت الجرعة؟» for the patient, «متى تم
/// أخذ الجرعة؟» for someone caring for them ([CareVoice]).
Future<DateTime?> selectTakenTime(
  BuildContext context,
  DateTime scheduledOn, {
  String? circleId,
}) async {
  final PatientClock clock = PatientClockScope.of(context);
  final selected = await showTafaqodTimeSheet(
    context,
    initialTime: TimeOfDay.fromDateTime(clock.now()),
    title: CareVoice.tr(context, circleId, 'medications.actual_time'),
  );
  if (selected == null) return null;
  return clock.momentOf(scheduledOn, '${selected.hour}:${selected.minute}');
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

String doseSkipReasonText(BuildContext context, DoseRecord record) {
  return doseSkipReasonLabel(
    context,
    record.skipReasonCode,
    record.skipReasonNote,
  );
}

String doseSkipReasonLabel(BuildContext context, String? code, String? note) {
  if (code == null) return '';
  if (code == 'other' && note?.isNotEmpty == true) {
    return note!;
  }
  final key = switch (code) {
    'side_effects' => 'sideEffects',
    'patient_refused' => 'patientRefused',
    _ => code,
  };
  return context.tr('medications.skip_reason.$key');
}
