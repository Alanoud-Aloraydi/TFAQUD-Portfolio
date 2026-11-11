import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The kind of a reading and when it was taken, on the patient's clock. A
/// skipped reading has only the day it was planned for.
class ReadingTitles extends StatelessWidget {
  const ReadingTitles({super.key, required this.reading});

  final MeasurementReading reading;

  String _when(BuildContext context) {
    if (reading.outcome == 'skipped') {
      return formatBirthDate(context, reading.scheduledOn!);
    }
    final PatientClock clock = PatientClockScope.of(context);
    final DateTime at = clock.wallTime(reading.measuredAt!);
    return '${formatBirthDate(context, at)} · ${wallTimeText(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool glucose = reading.kind == MeasurementKind.glucose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.tr(glucose ? 'measurements.glucose' : 'measurements.bp'),
          style: text.titleMedium,
        ),
        Text(
          _when(context),
          style: text.bodySmall?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
