import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/home/presentation/widgets/today_body.dart';
import 'package:app/features/home/presentation/widgets/today_load_error.dart';
import 'package:app/features/home/presentation/widgets/today_next_or_empty.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
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
