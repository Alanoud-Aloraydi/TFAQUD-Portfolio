import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «ذكّرني لاحقًا» put off by someone in the circle, while it waits.
String? measurementSnoozeText(
  BuildContext context,
  MeasurementOccurrence task,
  PatientClock clock,
) {
  final SharedSnooze? snooze = task.snooze;
  if (snooze == null || task.record != null) return null;
  final DateTime until = clock.wallTime(snooze.remindAt);
  if (!until.isAfter(clock.now())) return null;
  final String time = wallTimeText(until);
  return snooze.byName == null
      ? context.tr('measurements.snoozed_shared', args: <String>[time])
      : context.tr(
          'measurements.snoozed_by',
          args: <String>[time, snooze.byName!],
        );
}
