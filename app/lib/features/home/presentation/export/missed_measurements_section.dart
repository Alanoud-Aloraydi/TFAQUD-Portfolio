import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The scheduled measurements nobody recorded: the day, the time and, when
/// the plan names one, the condition to measure in.
RecordPdfSection missedMeasurementsSection(
  BuildContext context,
  RecordExportData data,
) {
  final missed = data.missedTasks;
  final yesterday = DateTime(
    data.today.year,
    data.today.month,
    data.today.day - 1,
  );
  return RecordPdfSection(
    title: context.tr('record_export.unrecorded_measurements'),
    empty: missed.isEmpty ? context.tr('record_export.none_unrecorded') : null,
    items: <RecordPdfItem>[
      for (final MeasurementOccurrence task in missed)
        RecordPdfItem(
          title: context.tr(
            task.kind == MeasurementKind.glucose
                ? 'measurements.glucose'
                : 'measurements.bp',
          ),
          badge: context.tr(
            DateUtils.dateOnly(task.scheduledOn).isBefore(yesterday)
                ? 'measurements.missed'
                : 'measurements.unrecorded',
          ),
          badgeMuted: true,
          detail: <RecordPdfRow>[
            RecordPdfRow(
              value:
                  '${formatBirthDate(context, task.scheduledOn)} | '
                  '${clockText(task.time)}',
            ),
            if (task.measurementState != null)
              RecordPdfRow(
                value: context.tr(
                  'measurements.condition.${task.measurementState}',
                ),
              ),
          ],
        ),
    ],
  );
}
