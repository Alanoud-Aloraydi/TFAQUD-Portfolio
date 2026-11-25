import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/presentation/cubit/record_export_collecting.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Each part of the record an export can hold, read for one period.
mixin RecordExportReads
    on Cubit<RecordExportState>, RecordExportScope, RecordExportChunks {
  Future<List<DoseOccurrence>> dosesIn(ExportPeriod period) =>
      chunked(period, (id, from, to) async {
        final result = await medications.getOccurrences(id, from, to);
        final values = result.tryGetSuccess();
        if (values == null) throw StateError('Medication export failed');
        return values;
      });

  Future<List<ExtraDose>> extraDosesIn(ExportPeriod period) =>
      chunked(period, (id, from, to) async {
        final result = await medications.getExtraDoses(id, from, to);
        final values = result.tryGetSuccess();
        if (values == null) throw StateError('Extra dose export failed');
        return values;
      });

  Future<List<MeasurementReading>> readingsIn(
    ExportPeriod period,
    PatientClock clock,
  ) async => [
    for (final reading in await measurements.allReadings(circleId))
      if (_readingDay(reading, clock) case final day? when period.contains(day))
        reading,
  ];

  /// The patient's calendar day a reading belongs to.
  DateTime? _readingDay(MeasurementReading reading, PatientClock clock) {
    final DateTime? at = reading.measuredAt;
    return at == null ? reading.scheduledOn : clock.wallTime(at);
  }

  Future<List<CareAppointment>> appointmentsIn(ExportPeriod period) async => [
    for (final item in await appointments.appointments(circleId))
      if (period.contains(item.scheduledOn)) item,
  ];

  Future<Map<String, VisitPaper>> visitPapersOf(
    List<CareAppointment> appointments,
  ) async {
    final completed = appointments.where(
      (item) => item.status == AppointmentStatus.completed,
    );
    final entries = await Future.wait(
      completed.map(
        (item) async => MapEntry(item.id, await visits.get(circleId, item.id)),
      ),
    );
    return {
      for (final entry in entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }
}

/// The server answers at most a month at a time, so a long period is read
/// in pieces.
mixin RecordExportChunks on Cubit<RecordExportState>, RecordExportScope {
  static const int _chunkDays = 31;

  Future<List<T>> chunked<T>(
    ExportPeriod period,
    Future<List<T>> Function(String circleId, DateTime from, DateTime to) read,
  ) async {
    final items = <T>[];
    var start = period.start;
    while (!start.isAfter(period.end)) {
      final candidate = DateTime(
        start.year,
        start.month,
        start.day + _chunkDays,
      );
      final end = candidate.isAfter(period.end) ? period.end : candidate;
      items.addAll(await read(circleId, start, end));
      start = DateTime(end.year, end.month, end.day + 1);
    }
    return items;
  }
}
