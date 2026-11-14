import 'dart:async';

import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_components.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    final (
      String headerKey,
      IconData icon,
      Color iconBackground,
    ) = medication != null
        ? (
            'today_dashboard.next_medication',
            CareVisuals.medicationIcon,
            CareVisuals.medicationTile,
          )
        : measurement != null
        ? (
            'today_dashboard.next_measurement',
            CareVisuals.measurementIcon,
            CareVisuals.measurementTile,
          )
        : (
            'today_dashboard.next_appointment',
            CareVisuals.appointmentIcon,
            CareVisuals.appointmentTile,
          );
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: AppSizes.avatar,
                    height: AppSizes.avatar,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.iconSmall,
                      color: AppSemanticColors.onSettingsTile,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(headerKey),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
