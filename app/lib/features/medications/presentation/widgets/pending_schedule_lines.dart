import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Each dose time of a waiting revision on its own line, «08:00، قرص واحد».
List<Widget> pendingScheduleLines(
  BuildContext context,
  List<MedicationSchedule> schedules,
) => <Widget>[
  for (final schedule in schedules)
    Text(
      context.tr(
        'medications.pending_schedule',
        args: [
          clockText(schedule.time),
          formatMedicationNumber(schedule.doseValue),
          context.tr('medications.unit.${schedule.doseUnit.name}'),
        ],
      ),
    ),
];
