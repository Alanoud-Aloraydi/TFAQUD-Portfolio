import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/measurement_row_texts.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:flutter/widgets.dart';

/// One reading's line in the exported record: the day, the time, the value,
/// what it means, the normal band and the notes.
List<RecordPdfCell> measurementRow(
  BuildContext context,
  RecordExportData data,
  MeasurementReading reading,
) {
  final bool skipped = reading.outcome == 'skipped';
  final DateTime? at = reading.measuredAt == null
      ? null
      : data.clock.wallTime(reading.measuredAt!);
  final bool outside = reading.outsideTarget == true;
  return <RecordPdfCell>[
    RecordPdfCell(formatBirthDate(context, at ?? reading.scheduledOn!)),
    RecordPdfCell(at == null ? '—' : wallTimeText(at)),
    RecordPdfCell(skipped ? '—' : reading.valueText, ltr: true, warn: outside),
    RecordPdfCell(readingStatusText(context, reading), warn: outside),
    RecordPdfCell(switch (reading.range) {
      final range? when !skipped => normalBandNumbers(
        reading.kind,
        range.normal,
      ),
      _ => '—',
    }, ltr: true),
    RecordPdfCell(readingNotesText(context, reading)),
  ];
}
