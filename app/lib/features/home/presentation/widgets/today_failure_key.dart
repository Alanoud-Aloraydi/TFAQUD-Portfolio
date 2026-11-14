import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
