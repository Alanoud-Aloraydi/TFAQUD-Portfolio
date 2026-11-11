import 'package:app/core/errors/failure.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Defines the supported record export status values.
enum RecordExportStatus { loading, ready }

/// Holds the record export presentation state.
class RecordExportState extends Equatable {
  const RecordExportState({
    this.status = RecordExportStatus.loading,
    this.medicalFile,
    this.errorKey,
    this.sharing = false,
  });

  final RecordExportStatus status;
  final MedicalFile? medicalFile;
  final String? errorKey;
  final bool sharing;

  @override
  List<Object?> get props => [status, medicalFile, errorKey, sharing];
}

/// Keeps medical data loading and PDF sharing outside the export sheet widget.
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

  final CirclesUseCase _circles;
  final RecordPdfExporter _exporter;
  final MeasurementRepository _measurements;
  final MedicationsUseCase _medications;
  final AppointmentRepository _appointments;
  final VisitRepository _visits;
  final String circleId;

  Future<List<MeasurementReading>> allMeasurements() =>
      _measurements.allReadings(circleId);

  Future<List<DoseOccurrence>> medicationOccurrences(
    DateTime from,
    DateTime to,
  ) async {
    final items = <DoseOccurrence>[];
    var start = from;
    while (!start.isAfter(to)) {
      final candidate = DateTime(start.year, start.month, start.day + 31);
      final end = candidate.isAfter(to) ? to : candidate;
      final result = await _medications.getOccurrences(circleId, start, end);
      final values = result.tryGetSuccess();
      if (values == null) throw StateError('Medication export failed');
      items.addAll(values);
      start = DateTime(end.year, end.month, end.day + 1);
    }
    return items;
  }

  Future<List<MeasurementOccurrence>> measurementOccurrences(
    DateTime from,
    DateTime to,
  ) async {
    final items = <MeasurementOccurrence>[];
    var start = from;
    while (!start.isAfter(to)) {
      final candidate = DateTime(start.year, start.month, start.day + 31);
      final end = candidate.isAfter(to) ? to : candidate;
      items.addAll(await _measurements.occurrences(circleId, start, end));
      start = DateTime(end.year, end.month, end.day + 1);
    }
    return items;
  }

  Future<List<CareAppointment>> allAppointments() =>
      _appointments.appointments(circleId);

  Future<Map<String, VisitPaper>> allVisits(
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

  /// [pageLabel] writes «صفحة 1 من 2» for the footer of each page.
  Future<String?> share({
    required String title,
    required String subtitle,
    required String appName,
    required String Function(int page, int pages) pageLabel,
    required List<RecordPdfSection> sections,
    required String filename,
  }) async {
    if (state.sharing || sections.isEmpty) return 'record_export.select_one';
    emit(
      RecordExportState(
        status: state.status,
        medicalFile: state.medicalFile,
        sharing: true,
      ),
    );
    try {
      await _exporter.share(
        title: title,
        subtitle: subtitle,
        appName: appName,
        pageLabel: pageLabel,
        sections: sections,
        filename: filename,
      );
      return null;
    } on Exception {
      return 'record_export.failed';
    } finally {
      if (!isClosed) {
        emit(
          RecordExportState(
            status: state.status,
            medicalFile: state.medicalFile,
          ),
        );
      }
    }
  }
}
