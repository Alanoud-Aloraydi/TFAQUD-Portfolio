import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// The readings of [month] grouped by the day they fall on where the patient
/// lives, never the phone's zone, each day in the order they were measured
/// (the server sends the last recorded first).
Map<int, List<MeasurementReading>> readingsByDay(
  List<MeasurementReading> readings,
  DateTime month,
  PatientClock clock,
) {
  final Map<int, List<MeasurementReading>> byDay =
      <int, List<MeasurementReading>>{};
  for (final MeasurementReading reading in readings) {
    final DateTime? moment = reading.measuredAt;
    if (moment == null) continue;
    final DateTime at = clock.wallTime(moment);
    if (at.year != month.year || at.month != month.month) continue;
    byDay.putIfAbsent(at.day, () => <MeasurementReading>[]).add(reading);
  }
  for (final List<MeasurementReading> day in byDay.values) {
    day.sort((a, b) => a.measuredAt!.compareTo(b.measuredAt!));
  }
  return byDay;
}
