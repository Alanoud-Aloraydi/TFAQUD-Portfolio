import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Why a recorded dose was not taken, in the words the sheet offered.
String doseSkipReasonText(BuildContext context, DoseRecord record) {
  return doseSkipReasonLabel(
    context,
    record.skipReasonCode,
    record.skipReasonNote,
  );
}

/// The reason behind [code], or the note itself when «أخرى» was chosen and
/// something was written. The server's older codes are read too.
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
