import 'dart:async';

import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_components.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The earliest open task of today: exactly one of [medication],
/// [measurement] and [appointment] is set, and [at] is its wall time.
typedef NextTask = ({
  DateTime at,
  DoseOccurrence? medication,
  MeasurementOccurrence? measurement,
  CareAppointment? appointment,
});

/// Selects the earliest open task from today's and future schedules, all
/// on the patient's wall clock ([now]).
NextTask? nearestTask(
  DateTime now,
  List<DoseOccurrence> medications,
  List<MeasurementOccurrence> measurements,
  List<CareAppointment> appointments,
) {
  final candidates = <NextTask>[
    for (final item in medications)
      if (medicationIsNextTaskCandidate(item, now))
        (
          at: wallClockAt(item.scheduledOn, item.time).isBefore(now)
              ? now
              : wallClockAt(item.scheduledOn, item.time),
          medication: item,
          measurement: null,
          appointment: null,
        ),
    for (final item in measurements)
      if (item.record == null &&
          !wallClockAt(item.scheduledOn, item.time).isBefore(now))
        (
          at: wallClockAt(item.scheduledOn, item.time),
          medication: null,
          measurement: item,
          appointment: null,
        ),
    for (final item in appointments)
      if (item.status == AppointmentStatus.scheduled &&
          !wallClockAt(item.scheduledOn, item.time).isBefore(now))
        (
          at: wallClockAt(item.scheduledOn, item.time),
          medication: null,
          measurement: null,
          appointment: item,
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return candidates.firstOrNull;
}

/// «المهمة القادمة»: the dose to act on now, or the next task with the time
/// left (and the way to record a reading that can be recorded already).
class NextTaskCard extends StatelessWidget {
  const NextTaskCard({
    super.key,
    required this.task,
    required this.circleId,
    required this.canManage,
    required this.now,
  });
  final NextTask task;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final medication = task.medication;
    final measurement = task.measurement;
    final appointment = task.appointment;
    final sameDay = DateUtils.isSameDay(task.at, now);
    if (medication != null && sameDay) {
      return TodayMedicationActionDose(
        occurrence: medication,
        circleId: circleId,
        canManage: canManage,
      );
    }
    final minutes = (task.at.difference(now).inSeconds + 59) ~/ 60;
    final relative = afterDuration(context, minutes);
    final title =
        medication?.name ??
        (measurement == null
            ? appointmentTitle(context, appointment!)
            : context.tr(
                measurement.kind == MeasurementKind.bp
                    ? 'measurements.bp'
                    : 'measurements.glucose',
              ));
    final time = medication?.time ?? measurement?.time ?? appointment!.time;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.textSupporting),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('today_dashboard.next_task'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${context.tr('common.weekdays.${task.at.weekday}')} '
              '${formatMedicationDate(context, task.at)} · '
              '${clockText(time)}',
            ),
            if (minutes < 2880)
              Text(relative, style: Theme.of(context).textTheme.titleMedium),
            if (appointment != null)
              Text(appointmentCompanionLine(context, appointment)),
            if (measurement != null &&
                sameDay &&
                canRecordOccurrence(
                  resolved:
                      measurement.status != MeasurementStatus.upcoming &&
                      measurement.status != MeasurementStatus.due &&
                      measurement.status != MeasurementStatus.missed,
                  scheduledAt: wallClockAt(
                    measurement.scheduledOn,
                    measurement.time,
                  ),
                  now: now,
                )) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                // The tasks read again by themselves when the answer is saved.
                onPressed: () => unawaited(
                  showMeasurementReadingSheet(context, occurrence: measurement),
                ),
                child: Text(context.tr('measurements.record_reading')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
