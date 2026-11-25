import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// What a reading meant: skipped, its level, or where it fell against the
/// target.
String readingStatusText(BuildContext context, MeasurementReading reading) {
  if (reading.outcome == 'skipped') return context.tr('measurements.skipped');
  if (reading.level case final level?) {
    return level.label(context, reading.kind);
  }
  return context.tr(switch (reading.outsideTarget) {
    true => 'measurements.outside_target',
    false => 'measurements.in_target',
    null => 'measurements.without_target',
  });
}

/// The conditions it was read in, why it was skipped, and the typed note.
String readingNotesText(BuildContext context, MeasurementReading reading) {
  final List<String> parts = <String>[
    if (reading.outcome == 'read' && reading.conditions.isNotEmpty)
      readingConditionsText(context, reading),
    if (reading.outcome == 'skipped' && reading.skipReasonCode != null)
      measurementSkipReasonText(context, reading),
    if (reading.note?.isNotEmpty == true) reading.note!,
  ];
  return parts.isEmpty ? '—' : parts.join('، ');
}
