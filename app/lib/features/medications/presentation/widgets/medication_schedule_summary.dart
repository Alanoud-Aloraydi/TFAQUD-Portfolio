import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/widgets.dart';

/// A medicine's whole day in one line, «08:00، قرص، 20:00، قرص»: for the
/// boxes that compare one schedule against another and have no room for a
/// list.
String medicationScheduleSummary(
  BuildContext context,
  List<MedicationSchedule> schedules,
) => schedules
    .map(
      (schedule) =>
          '${clockText(schedule.time)}، '
          '${formatMedicationDose(context, schedule.doseValue, schedule.doseUnit)}',
    )
    .join('، ');
