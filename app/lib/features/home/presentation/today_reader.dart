import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/home/presentation/today_snapshot.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
