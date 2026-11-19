import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';

/// The readings of [month] grouped by their day of it (1 is its first, in
/// either calendar) where the patient lives, never the phone's zone, each
/// day in the order they were measured (the server sends the last recorded
/// first).
Map<int, List<MeasurementReading>> readingsByDay(
  List<MeasurementReading> readings,
  CalendarMonth month,
  PatientClock clock,
) {
  final Map<int, List<MeasurementReading>> byDay =
      <int, List<MeasurementReading>>{};
  for (final MeasurementReading reading in readings) {
    final DateTime? moment = reading.measuredAt;
    if (moment == null) continue;
    final int? day = month.numberOf(clock.wallTime(moment));
    if (day == null) continue;
    byDay.putIfAbsent(day, () => <MeasurementReading>[]).add(reading);
  }
  for (final List<MeasurementReading> day in byDay.values) {
    day.sort((a, b) => a.measuredAt!.compareTo(b.measuredAt!));
  }
  return byDay;
}
