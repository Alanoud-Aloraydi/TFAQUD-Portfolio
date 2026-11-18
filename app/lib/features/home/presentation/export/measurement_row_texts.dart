import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
