import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/home/domain/entities/overdue_tasks.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_view.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_midnight.dart';
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

/// Today's prayer times, or null while they load (or are yesterday's).
PrayerDay? todayPrayerDay(PrayerTimesState prayers, DateTime now) =>
    prayers.day != null && DateUtils.isSameDay(prayers.day!.date, now)
    ? prayers.day
    : null;
