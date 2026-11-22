import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/home/domain/overdue_tasks.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/today_medication_view.dart';
import 'package:flutter/material.dart';

/// What «اليوم» shows on the patient's clock: the day's rows and the rest.
class TodaySnapshot {
  TodaySnapshot({
    required MedicationOccurrencesState doses,
    required List<MeasurementOccurrence> tasks,
    required List<MeasurementReading> readings,
    required List<CareAppointment> appointments,
    required PatientClock clock,
  }) : now = clock.now(),
       medications = TodayMedicationView(
         doses.status == MedicationOccurrencesStatus.loading ||
                 doses.status == MedicationOccurrencesStatus.failure
             ? const <DoseOccurrence>[]
             : doses.occurrences,
         clock.now(),
       ) {
    todayMeasurements = tasks
        .where((task) => DateUtils.isSameDay(task.scheduledOn, now))
        .toList();
    todayAppointments = appointments
        .where(
          (item) => item.isOpen && DateUtils.isSameDay(item.scheduledOn, now),
        )
        .toList();
    overdueMeasurements = OverdueTasks.measurements(tasks, clock.today());
    overdueAppointments = OverdueTasks.appointments(
      appointments,
      clock.today(),
      now: now,
      doses: medications.todayOccurrences,
      measurements: todayMeasurements,
    );
    measurementAttention = MeasurementAttention.count(
      overdueMeasurements,
      readings,
      clock,
    );
  }

  final DateTime now;
  final TodayMedicationView medications;
  late final List<MeasurementOccurrence> todayMeasurements;
  late final List<CareAppointment> todayAppointments;
  late final List<MeasurementOccurrence> overdueMeasurements;
  late final List<CareAppointment> overdueAppointments;
  late final int measurementAttention;

  /// How many cards the one «يحتاج انتباهك» box shows besides the doses.
  int get extraCount => measurementAttention + overdueAppointments.length;

  bool get needsAttention => medications.attention.isNotEmpty || extraCount > 0;

  bool get dayIsEmpty =>
      medications.todayOccurrences.isEmpty &&
      todayMeasurements.isEmpty &&
      todayAppointments.isEmpty;
}
