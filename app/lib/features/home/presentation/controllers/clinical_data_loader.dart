import 'dart:async';

import 'package:app/core/utils/overdue_window.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';

/// The days «اليوم» reads doses for: from the first overdue day (a missed
/// dose can still be answered) to a month ahead (the next-task card),
/// counted in calendar days of the patient's [today].
({DateTime from, DateTime to}) occurrenceWindow(DateTime today) =>
    (from: overdueStart(today), to: addDays(today, 30));

/// Reads the shown circle's data into the cubits of the home tabs, and
/// again when the patient's day changes.
///
/// After that the cubits keep themselves fresh from their repositories'
/// change streams; this only starts them, so no screen reloads by hand.
class ClinicalDataLoader {
  ClinicalDataLoader({
    required this.medications,
    required this.measurementPlans,
    required this.appointments,
    required this.measurementTasks,
    required this.measurementReadings,
    required this.occurrences,
    required this.prayers,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The branch of the «اليوم» tab and of the circle tab.
  static const int todayTab = 0;
  static const int circleTab = 3;

  final MedicationsCubit medications;
  final MeasurementPlansCubit measurementPlans;
  final AppointmentsCubit appointments;
  final MeasurementTasksCubit measurementTasks;
  final MeasurementReadingsCubit measurementReadings;
  final MedicationOccurrencesCubit occurrences;
  final PrayerTimesCubit prayers;
  final DateTime Function() _clock;

  Timer? _midnight;
  bool _disposed = false;

  /// Whether the circle tab was open since the prayer times were read: the
  /// patient's city is edited there.
  bool _prayersStale = false;

  /// Reads [circle]'s data for the patient's today, and again at the
  /// patient's next midnight.
  ///
  /// With [quiet] (the app came back to the front) what is shown stays
  /// while it is read again.
  void load(CareCircleSummary circle, {bool quiet = false}) {
    final String circleId = circle.id;
    final PatientClock clock = circle.clock;
    final DateTime today = clock.today();
    final window = occurrenceWindow(today);
    unawaited(medications.load(circleId, silent: quiet));
    unawaited(measurementPlans.load(circleId, silent: quiet));
    unawaited(appointments.load(circleId, silent: quiet));
    unawaited(measurementTasks.load(circleId, today, silent: quiet));
    unawaited(measurementReadings.load(circleId, today, today, silent: quiet));
    unawaited(
      occurrences.load(circleId, window.from, window.to, silent: quiet),
    );
    unawaited(prayers.load(circleId, circle.timeZone));
    _midnight?.cancel();
    final DateTime midnight = clock.momentOf(addDays(today, 1), '00:00');
    _midnight = Timer(midnight.difference(_clock()), () {
      if (!_disposed) load(circle);
    });
  }

  /// The person moved from tab [from] to tab [to]. Back on «اليوم» after the
  /// circle tab, where the city can change, the prayer times are read again.
  void tabChanged(int from, int to, CareCircleSummary? circle) {
    if (from == circleTab) _prayersStale = true;
    if (to == todayTab && _prayersStale && circle != null) {
      _prayersStale = false;
      unawaited(prayers.load(circle.id, circle.timeZone, refresh: true));
    }
  }

  void dispose() {
    _disposed = true;
    _midnight?.cancel();
  }
}
