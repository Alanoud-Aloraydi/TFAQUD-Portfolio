import 'package:app/core/widgets/overlays/skip_reason_sheet.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks why the reading is skipped (optional) with the app's one skip
/// sheet, and returns the skipped reading to save; null when it is closed.
Future<MeasurementReadingDraft?> selectSkippedMeasurement(
  BuildContext context,
  MeasurementKind kind,
) async {
  final SkipReasonChoice? choice = await showSkipReasonSheet(
    context,
    title: context.tr('measurements.skip_title'),
    message: context.tr('measurements.skip_reason_optional'),
    reasons: <SkipReasonOption>[
      for (final MeasurementSkipReason reason in MeasurementSkipReason.values)
        SkipReasonOption(
          reason.apiValue,
          context.tr('measurements.skip_reason.${reason.name}'),
        ),
    ],
    noteLabel: context.tr('measurements.skip_reason_note'),
    confirmLabel: context.tr('measurements.skip_confirm'),
  );
  if (choice == null) return null;
  return MeasurementReadingDraft(
    kind: kind,
    outcome: 'skipped',
    skipReasonCode: choice.code,
    skipReasonNote: choice.note,
  );
}

String measurementSkipReasonText(
  BuildContext context,
  MeasurementReading reading,
) {
  final code = reading.skipReasonCode;
  if (code == null) return '';
  if (code == 'other' && reading.skipReasonNote?.isNotEmpty == true) {
    return reading.skipReasonNote!;
  }
  final key = switch (code) {
    'equipment_unavailable' => 'equipmentUnavailable',
    'patient_refused' => 'patientRefused',
    _ => code,
  };
  return context.tr('measurements.skip_reason.$key');
}
