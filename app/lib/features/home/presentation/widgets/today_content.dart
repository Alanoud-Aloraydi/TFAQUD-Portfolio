import 'dart:async';

import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/widgets/overdue_appointment_card.dart';
import 'package:app/features/home/presentation/widgets/today_next_or_empty.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/home/presentation/widgets/today_schedule.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_attention_section.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_midnight.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What «اليوم» holds under its title: the failure, the next task, and the
/// body with what needs attention and the day's schedule.
class TodayContent extends StatelessWidget {
  const TodayContent({
    super.key,
    required this.circleId,
    required this.canManage,
    this.onAdd,
  });

  final String circleId;
  final bool canManage;

  /// Opens the add sheet from the note of an empty day; null for a member
  /// who only reads.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<MedicationOccurrencesCubit>().state.status;
    final (snapshot, next) = readToday(context);
    final String? errorKey = todayFailureKey(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (status == MedicationOccurrencesStatus.loading)
          const DoseRowSkeleton(withButtons: true),
        if (errorKey != null)
          TodayLoadError(messageKey: errorKey, circleId: circleId),
        TodayNextOrEmpty(
          snapshot: snapshot,
          next: next,
          settled:
              status == MedicationOccurrencesStatus.ready && errorKey == null,
          circleId: circleId,
          canManage: canManage,
          onAdd: onAdd,
        ),
        TodayBody(snapshot: snapshot, circleId: circleId, canManage: canManage),
      ],
    );
  }
}

/// Reads every cubit of «اليوم» (and rebuilds [context] when one changes)
/// into what the tab shows, with the next task over all planned days.
(TodaySnapshot, NextTask?) readToday(BuildContext context) {
  final doses = context.watch<MedicationOccurrencesCubit>().state;
  final tasks = context.watch<MeasurementTasksCubit>().state.tasks;
  final readings = context.watch<MeasurementReadingsCubit>().state.readings;
  final appointments = context.watch<AppointmentsCubit>().state.appointments;
  final snapshot = TodaySnapshot(
    doses: doses,
    tasks: tasks,
    readings: readings,
    appointments: appointments,
    clock: PatientClockScope.of(context),
  );
  return (
    snapshot,
    nearestTask(snapshot.now, doses.occurrences, tasks, appointments),
  );
}

/// The box of what needs attention (overdue days included) and the day's
/// schedule under it.
class TodayBody extends StatelessWidget {
  const TodayBody({
    super.key,
    required this.snapshot,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final prayers = context.watch<PrayerTimesCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (snapshot.needsAttention) ...<Widget>[
          TodayAttention(
            snapshot: snapshot,
            circleId: circleId,
            canManage: canManage,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        SectionHeader(context.tr('today_dashboard.schedule')),
        const SizedBox(height: AppSpacing.md),
        TodaySchedule(
          snapshot: snapshot,
          day: todayPrayerDay(prayers, snapshot.now),
          circleId: circleId,
          canManage: canManage,
        ),
      ],
    );
  }
}

/// The one «يحتاج انتباهك» box: the doses, then the measurements, then the
/// appointments of earlier days, all of the overdue days still open. The
/// card a tapped notification is about is brought into view and tinted.
class TodayAttention extends StatelessWidget {
  const TodayAttention({
    super.key,
    required this.snapshot,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final readings = context.watch<MeasurementReadingsCubit>().state.readings;
    return TodayMedicationAttentionSection(
      occurrences: snapshot.medications.attention,
      circleId: circleId,
      canManage: canManage,
      extraCount: snapshot.extraCount,
      focusKeys: attentionFocusKeys(snapshot, circleId),
      extra: snapshot.extraCount == 0
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MeasurementAttentionSection(
                  tasks: snapshot.overdueMeasurements,
                  readings: readings,
                  boxed: false,
                  circleId: circleId,
                ),
                for (final item in snapshot.overdueAppointments)
                  FocusMark(
                    itemKey: appointmentItemKey(circleId, item.id),
                    radius: AppRadius.field,
                    inset: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: OverdueAppointmentCard(
                      value: item,
                      circleId: circleId,
                      canManage: canManage,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Every item of the «يحتاج انتباهك» box of [snapshot], as a tapped
/// notification names it (item_keys.dart): its doses, its measurements and
/// its visits.
Set<String> attentionFocusKeys(TodaySnapshot snapshot, String circleId) =>
    <String>{
      for (final dose in snapshot.medications.attention)
        doseSnoozeKey(circleId, dose),
      for (final task in snapshot.overdueMeasurements)
        measurementSnoozeKey(circleId, task),
      for (final item in snapshot.overdueAppointments)
        appointmentItemKey(circleId, item.id),
    };

/// The message of a failed read with «إعادة المحاولة», which reads again
/// every part that failed.
class TodayLoadError extends StatelessWidget {
  const TodayLoadError({
    super.key,
    required this.messageKey,
    required this.circleId,
  });

  final String messageKey;
  final String circleId;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(context.tr(messageKey), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _retry(context),
          child: Text(context.tr('auth.retry')),
        ),
      ],
    ),
  );

  void _retry(BuildContext context) {
    final doses = context.read<MedicationOccurrencesCubit>();
    final tasks = context.read<MeasurementTasksCubit>();
    final readings = context.read<MeasurementReadingsCubit>();
    final appointments = context.read<AppointmentsCubit>();
    final prayers = context.read<PrayerTimesCubit>();
    if (doses.state.status == MedicationOccurrencesStatus.failure) {
      unawaited(doses.reload());
    }
    if (tasks.state.status == MeasurementLoadStatus.failure) {
      unawaited(tasks.reload());
    }
    if (readings.state.status == MeasurementLoadStatus.failure) {
      unawaited(readings.reload());
    }
    if (appointments.state.status == AppointmentsLoadStatus.failure) {
      unawaited(appointments.load(circleId));
    }
    if (prayers.state.status == PrayerTimesStatus.failure) {
      unawaited(prayers.reload());
    }
  }
}

/// The first message key of a cubit of «اليوم» that failed, or null.
String? todayFailureKey(BuildContext context) {
  final doses = context.watch<MedicationOccurrencesCubit>().state;
  final tasks = context.watch<MeasurementTasksCubit>().state;
  final readings = context.watch<MeasurementReadingsCubit>().state;
  final appointments = context.watch<AppointmentsCubit>().state;
  final prayers = context.watch<PrayerTimesCubit>().state;
  return <String>[
    if (doses.status == MedicationOccurrencesStatus.failure)
      doses.messageKey ?? 'error.unknown',
    if (tasks.status == MeasurementLoadStatus.failure)
      tasks.errorKey ?? 'error.unknown',
    if (readings.status == MeasurementLoadStatus.failure)
      readings.errorKey ?? 'error.unknown',
    if (appointments.status == AppointmentsLoadStatus.failure)
      appointments.errorKey ?? 'error.unknown',
    if (prayers.status == PrayerTimesStatus.failure) 'prayer_times.unavailable',
  ].firstOrNull;
}
