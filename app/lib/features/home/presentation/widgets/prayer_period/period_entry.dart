import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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
