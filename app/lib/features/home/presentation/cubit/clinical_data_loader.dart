import 'dart:async';

import 'package:app/core/utils/overdue_window.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/clinical_data_reads.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';

export 'package:app/features/home/presentation/cubit/clinical_data_reads.dart';

/// Reads the shown circle's data into the home tabs' cubits, again at the
/// patient's midnight and when a main page is pulled down; between those
/// the cubits keep fresh from their repositories' change streams.
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

  final MidnightTimer _midnight = MidnightTimer();

  /// Whether the circle tab, where the city is edited, was open since.
  bool _prayersStale = false;

  /// Reads [circle]'s data, and again at the patient's next midnight. With
  /// [quiet] (back to the front) what is shown stays while it is read.
  void load(CareCircleSummary circle, {bool quiet = false}) {
    unawaited(Future.wait(readAll(circle, quiet: quiet)));
    _midnight.schedule(circle, _clock, () => load(circle));
  }

  /// Back on «اليوم» from the circle tab, the prayer times are read again.
  void tabChanged(int from, int to, CareCircleSummary? circle) {
    if (from == circleTab) _prayersStale = true;
    if (to == todayTab && _prayersStale && circle != null) {
      _prayersStale = false;
      unawaited(prayers.load(circle.id, circle.timeZone, refresh: true));
    }
  }

  void dispose() {
    _midnight.dispose();
  }
}

/// The days «اليوم» reads doses for, in calendar days of the patient's
/// [today]: from the first overdue day to a month ahead.
({DateTime from, DateTime to}) occurrenceWindow(DateTime today) =>
    (from: overdueStart(today), to: addDays(today, 30));

/// Fires once at the patient's next midnight, and again only if scheduled
/// again; it stays silent after [dispose].
class MidnightTimer {
  Timer? _timer;
  bool _disposed = false;

  /// Replaces any earlier wait with one until the patient's next midnight.
  void schedule(
    CareCircleSummary circle,
    DateTime Function() clock,
    void Function() fire,
  ) {
    final DateTime today = circle.clock.today();
    _timer?.cancel();
    final DateTime midnight = circle.clock.momentOf(addDays(today, 1), '00:00');
    _timer = Timer(midnight.difference(clock()), () {
      if (!_disposed) fire();
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
