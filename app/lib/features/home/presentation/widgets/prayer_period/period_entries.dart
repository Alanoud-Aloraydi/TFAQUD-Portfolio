import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';

/// One task of a prayer period: exactly one of the three kinds is set.
class PeriodEntry {
  PeriodEntry.dose(DoseOccurrence item)
    : time = item.time,
      dose = item,
      measurement = null,
      visit = null;
  PeriodEntry.measurement(MeasurementOccurrence item)
    : time = item.time,
      dose = null,
      measurement = item,
      visit = null;
  PeriodEntry.visit(CareAppointment item)
    : time = item.time,
      dose = null,
      measurement = null,
      visit = item;

  final String time;
  final DoseOccurrence? dose;
  final MeasurementOccurrence? measurement;
  final CareAppointment? visit;
}

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

  int get missedMeasurements => measurements
      .where((item) => item.status == MeasurementStatus.missed)
      .length;

  /// All tasks of the period, earliest first.
  List<PeriodEntry> get sorted => <PeriodEntry>[
    for (final item in doses) PeriodEntry.dose(item),
    for (final item in measurements) PeriodEntry.measurement(item),
    for (final item in visits) PeriodEntry.visit(item),
  ]..sort((first, second) => first.time.compareTo(second.time));
}
