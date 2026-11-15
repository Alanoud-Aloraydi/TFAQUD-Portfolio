import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_row.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entries.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/period_entry_key.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_row.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_row.dart';
import 'package:flutter/material.dart';

/// The rows opened under a prayer period, one per task, with a gap between.
/// The row a tapped notification is about is brought into view and
/// outlined ([FocusMark]).
List<Widget> periodTaskRows(
  List<PeriodEntry> entries, {
  required String circleId,
  required bool canManage,
  required bool hasPhoto,
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
          showThumbnail: hasPhoto,
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
