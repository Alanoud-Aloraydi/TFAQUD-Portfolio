import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/home/presentation/widgets/period_task_rows.dart';
import 'package:app/features/home/presentation/widgets/prayer_period_view.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';

/// The doses, readings and visits whose nearest prayer is [prayer].
class PeriodEntries {
  PeriodEntries(
    Prayer prayer,
    Map<Prayer, String> prayerTimes, {
    required List<DoseOccurrence> occurrences,
    required List<MeasurementOccurrence> measurementTasks,
    required List<CareAppointment> appointments,
  }) {
    List<T> mine<T>(List<T> all, String Function(T) timeOf) => all
        .where((item) => nearestPrayer(timeOf(item), prayerTimes) == prayer)
        .toList();
    doses = mine(occurrences, (item) => item.time);
    measurements = mine(measurementTasks, (item) => item.time);
    visits = mine(appointments, (item) => item.time);
  }

  late final List<DoseOccurrence> doses;
  late final List<MeasurementOccurrence> measurements;
  late final List<CareAppointment> visits;

  /// All tasks of the period, earliest first.
  List<PeriodEntry> get sorted => <PeriodEntry>[
    for (final item in doses) PeriodEntry.dose(item),
    for (final item in measurements) PeriodEntry.measurement(item),
    for (final item in visits) PeriodEntry.visit(item),
  ]..sort((first, second) => first.time.compareTo(second.time));
}
