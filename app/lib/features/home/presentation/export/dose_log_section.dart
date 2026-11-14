import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Every dose that was recorded or missed, with how it ended and who wrote it.
RecordPdfSection doseLogSection(BuildContext context, RecordExportData data) {
  final visible = data.doses.where(
    (d) => d.record != null || d.timingState == DoseTimingState.missed,
  );
  return RecordPdfSection(
    title: context.tr('record_export.dose_log'),
    empty: visible.isEmpty ? context.tr('medications.no_dose_history') : null,
    items: <RecordPdfItem>[
      for (final DoseOccurrence dose in visible) _item(context, data, dose),
    ],
  );
}

String _badge(
  BuildContext context,
  RecordExportData data,
  DoseOccurrence dose,
) {
  final DoseOutcome? outcome = dose.record?.outcome;
  if (outcome == DoseOutcome.taken) {
    return context.tr('today_dashboard.status.taken');
  }
  if (outcome == DoseOutcome.skipped) {
    return context.tr('today_dashboard.status.skipped');
  }
  final DateTime yesterday = DateTime(
    data.today.year,
    data.today.month,
    data.today.day - 1,
  );
  final bool old = DateUtils.dateOnly(dose.scheduledOn).isBefore(yesterday);
  return context.tr(
    old ? 'medications.timing.missed' : 'medications.timing.unrecorded',
  );
}

RecordPdfItem _item(
  BuildContext context,
  RecordExportData data,
  DoseOccurrence dose,
) {
  final record = dose.record;
  return RecordPdfItem(
    title: dose.name,
    badge: _badge(context, data, dose),
    badgeMuted: record?.outcome != DoseOutcome.taken,
    detail: <RecordPdfRow>[
      RecordPdfRow(
        value:
            '${formatBirthDate(context, dose.scheduledOn)} | '
            '${clockText(dose.time)}',
      ),
    ],
    fields: <RecordPdfRow>[
      if (record != null &&
          record.outcome == DoseOutcome.skipped &&
          record.skipReasonCode != null)
        RecordPdfRow(
          label: context.tr('record_export.skip_reason'),
          value: doseSkipReasonText(context, record),
        ),
      if (record?.recordedByName case final name?)
        RecordPdfRow(
          label: context.tr('record_export.recorded_by'),
          value: name,
        ),
    ],
  );
}
