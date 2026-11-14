import 'package:app/core/errors/failure.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the record for an export and shares the PDF, outside the sheet.
class RecordExportCubit extends Cubit<RecordExportState> {
  RecordExportCubit(
    this._circles,
    this._exporter,
    this._measurements,
    this._medications,
    this._appointments,
    this._visits,
    this.circleId,
  ) : super(const RecordExportState());

  static const int _chunkDays = 31;

  final CirclesUseCase _circles;
  final RecordExporter _exporter;
  final MeasurementsUseCase _measurements;
  final MedicationsUseCase _medications;
  final AppointmentsUseCase _appointments;
  final VisitsUseCase _visits;
  final String circleId;

  Future<void> load() async {
    final result = await _circles.getMedicalFile(circleId);
    if (isClosed) return;
    result.when(
      (MedicalFile file) => emit(
        RecordExportState(status: RecordExportStatus.ready, medicalFile: file),
      ),
      (Failure failure) => emit(
        RecordExportState(
          status: RecordExportStatus.ready,
          errorKey: failure.messageKey,
        ),
      ),
    );
  }

  /// Reads what [options] ask for inside [period]. Emits an error and returns
  /// null when any read fails.
  Future<RecordExportData?> collect({
    required RecordExportOptions options,
    required ExportPeriod period,
    required PatientClock clock,
    required List<MedicationPlan> plans,
  }) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final appointments = options.appointments
          ? await _appointmentsIn(period)
          : const <CareAppointment>[];
      final data = RecordExportData(
        options: options,
        period: period,
        clock: clock,
        plans: plans,
        medicalFile: options.patient ? state.medicalFile : null,
        doses: options.medications ? await _doses(period) : const [],
        readings: options.measurements
            ? await _readings(period, clock)
            : const [],
        measurementTasks: options.measurements
            ? await _chunked(period, _measurements.occurrences)
            : const [],
        appointments: appointments,
        visits: options.detailed ? await _visitPapers(appointments) : const {},
      );
      if (!isClosed) emit(state.copyWith(busy: false));
      return data;
    } on Exception {
      if (!isClosed) {
        emit(state.copyWith(busy: false, errorKey: 'record_export.failed'));
      }
      return null;
    }
  }

  /// [pageLabel] writes «صفحة 1 من 2» for the footer of each page. Returns
  /// whether the file was shared.
  Future<bool> share({
    required RecordPdfDocument document,
    required String Function(int page, int pages) pageLabel,
    required String filename,
  }) async {
    if (state.busy || document.sections.isEmpty) {
      emit(state.copyWith(errorKey: 'record_export.select_one'));
      return false;
    }
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _exporter.share(
        document: document,
        pageLabel: pageLabel,
        filename: filename,
      );
      return true;
    } on Exception {
      if (!isClosed) emit(state.copyWith(errorKey: 'record_export.failed'));
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<List<DoseOccurrence>> _doses(ExportPeriod period) =>
      _chunked(period, (id, from, to) async {
        final result = await _medications.getOccurrences(id, from, to);
        final values = result.tryGetSuccess();
        if (values == null) throw StateError('Medication export failed');
        return values;
      });

  Future<List<MeasurementReading>> _readings(
    ExportPeriod period,
    PatientClock clock,
  ) async => [
    for (final reading in await _measurements.allReadings(circleId))
      if (_readingDay(reading, clock) case final day? when period.contains(day))
        reading,
  ];

  /// The patient's calendar day a reading belongs to.
  DateTime? _readingDay(MeasurementReading reading, PatientClock clock) {
    final DateTime? at = reading.measuredAt;
    return at == null ? reading.scheduledOn : clock.wallTime(at);
  }

  Future<List<CareAppointment>> _appointmentsIn(ExportPeriod period) async => [
    for (final item in await _appointments.appointments(circleId))
      if (period.contains(item.scheduledOn)) item,
  ];

  Future<Map<String, VisitPaper>> _visitPapers(
    List<CareAppointment> appointments,
  ) async {
    final completed = appointments.where(
      (item) => item.status == AppointmentStatus.completed,
    );
    final entries = await Future.wait(
      completed.map(
        (item) async => MapEntry(item.id, await _visits.get(circleId, item.id)),
      ),
    );
    return {
      for (final entry in entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  /// The server answers at most a month at a time, so a long period is read
  /// in pieces.
  Future<List<T>> _chunked<T>(
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
