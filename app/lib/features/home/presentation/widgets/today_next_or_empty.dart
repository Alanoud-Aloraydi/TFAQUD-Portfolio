import 'dart:async';

import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_actions.dart';
import 'package:app/features/home/presentation/widgets/next_task_summary.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_action_dose.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The next-task card, or the note that nothing is planned (or left) today.
/// The notes show only once [settled]: everything is read, with no failure.
class TodayNextOrEmpty extends StatelessWidget {
  const TodayNextOrEmpty({
    super.key,
    required this.snapshot,
    required this.next,
    required this.settled,
    required this.circleId,
    required this.canManage,
    this.onAdd,
  });

  final TodaySnapshot snapshot;
  final NextTask? next;
  final bool settled;
  final String circleId;
  final bool canManage;

  /// Opens the add sheet; null for a member who only reads, and the notes
  /// then have no button.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final NextTask? next = this.next;
    final bool nothingLeft =
        settled &&
        snapshot.medications.todayOccurrences.isNotEmpty &&
        snapshot.medications.attention.isEmpty &&
        snapshot.todayMeasurements.isEmpty &&
        snapshot.todayAppointments.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (settled && snapshot.dayIsEmpty)
          TodayEmptyNote(
            CareVoice.tr(context, circleId, 'today_dashboard.no_tasks_today'),
            onAdd: onAdd,
          ),
        if (next != null)
          NextTaskCard(
            task: next,
            circleId: circleId,
            canManage: canManage,
            now: snapshot.now,
          ),
        if (next != null) const SizedBox(height: AppSpacing.md),
        if (next == null && nothingLeft)
          TodayEmptyNote(
            context.tr('today_dashboard.no_remaining_tasks'),
            onAdd: onAdd,
          ),
      ],
    );
  }
}

/// A note on «اليوم» that nothing is planned (or left), with the button
/// that opens the add sheet when [onAdd] is not null.
class TodayEmptyNote extends StatelessWidget {
  const TodayEmptyNote(this.text, {super.key, required this.onAdd});

  final String text;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: EmptyStateNote(
      text,
      actionLabel: onAdd == null ? null : context.tr('add.title'),
      onAction: onAdd,
    ),
  );
}

/// «المهمة القادمة»: the dose to act on now, or the next task with the time
/// left, and what can be answered on it already ([NextTaskAction]).
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
    final sameDay = DateUtils.isSameDay(task.at, now);
    if (medication != null && sameDay) {
      return TodayMedicationActionDose(
        occurrence: medication,
        circleId: circleId,
        canManage: canManage,
      );
    }
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
            NextTaskSummary(task: task, circleId: circleId, now: now),
            NextTaskAction(
              task: task,
              circleId: circleId,
              canManage: canManage,
              now: now,
            ),
          ],
        ),
      ),
    );
  }
}

/// What «المهمة القادمة» answers on the card itself: a reading that can be
/// recorded already, or a visit's buttons as its row in «اليوم» has them
/// ([appointmentTodayActions]).
class NextTaskAction extends StatelessWidget {
  const NextTaskAction({
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

  static const EdgeInsets _gap = EdgeInsets.only(top: AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    final Widget? action = _action(context);
    if (action == null) return const SizedBox.shrink();
    return Padding(padding: _gap, child: action);
  }

  Widget? _action(BuildContext context) {
    final MeasurementOccurrence? measurement = task.measurement;
    if (measurement != null &&
        DateUtils.isSameDay(task.at, now) &&
        canRecordOccurrence(
          resolved:
              measurement.status != MeasurementStatus.upcoming &&
              measurement.status != MeasurementStatus.due &&
              measurement.status != MeasurementStatus.missed,
          scheduledAt: wallClockAt(measurement.scheduledOn, measurement.time),
          now: now,
        )) {
      // The tasks read again by themselves when the answer is saved.
      return FilledButton(
        onPressed: () => unawaited(
          showMeasurementReadingSheet(context, occurrence: measurement),
        ),
        child: Text(context.tr('measurements.record_reading')),
      );
    }
    final appointment = task.appointment;
    if (appointment == null) return null;
    return appointmentTodayActions(
      context,
      value: appointment,
      now: now,
      circleId: circleId,
      canManage: canManage,
    );
  }
}
