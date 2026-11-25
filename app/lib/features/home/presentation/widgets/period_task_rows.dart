import 'package:app/core/reminders/item_keys.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_row.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_row.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_row.dart';
import 'package:flutter/material.dart';

/// The rows opened under a prayer period, one per task, with a gap between.
/// The row a tapped notification is about is brought into view and
/// outlined ([FocusMark]).
List<Widget> periodTaskRows(
  List<PeriodEntry> entries, {
  required String circleId,
  required bool canManage,
  required DateTime now,
}) => <Widget>[
  for (final PeriodEntry entry in entries) ...<Widget>[
    FocusMark(
      itemKey: periodEntryKey(entry, circleId),
      radius: AppRadius.s,
      child: switch (entry) {
        PeriodEntry(dose: final item?) => TodayDoseRow(
          occurrence: item,
          circleId: circleId,
          canManage: canManage,
          now: now,
        ),
        PeriodEntry(measurement: final task?) => MeasurementTaskRow(
          task: task,
          now: now,
          circleId: circleId,
        ),
        PeriodEntry(visit: final visit?) => AppointmentTodayRow(
          value: visit,
          circleId: circleId,
          canManage: canManage,
        ),
        _ => const SizedBox.shrink(),
      },
    ),
    if (entry != entries.last) const SizedBox(height: AppSpacing.sm),
  ],
];

/// One task of a prayer period: exactly one of the three kinds is set.
class PeriodEntry {
  PeriodEntry.dose(DoseOccurrence item)
    : time = item.time,
      dose = item,
      measurement = null,
      visit = null;
  PeriodEntry.measurement(MeasurementOccurrence item)
    : time = item.time,
      dose = null,
      measurement = item,
      visit = null;
  PeriodEntry.visit(CareAppointment item)
    : time = item.time,
      dose = null,
      measurement = null,
      visit = item;

  final String time;
  final DoseOccurrence? dose;
  final MeasurementOccurrence? measurement;
  final CareAppointment? visit;
}

/// The key of an entry's item, as a tapped notification names it
/// (item_keys.dart): a dose and a reading by their snooze key, a visit by
/// its circle and id.
String periodEntryKey(PeriodEntry entry, String circleId) => switch (entry) {
  PeriodEntry(dose: final dose?) => doseSnoozeKey(circleId, dose),
  PeriodEntry(measurement: final task?) => measurementSnoozeKey(circleId, task),
  PeriodEntry(visit: final visit?) => appointmentItemKey(circleId, visit.id),
  _ => '',
};
