import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/presentation/cubit/record_export_reads.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Gathering every part of the record an export asks for.
mixin RecordExportCollecting
    on
        Cubit<RecordExportState>,
        RecordExportScope,
        RecordExportChunks,
        RecordExportReads {
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
          ? await appointmentsIn(period)
          : const <CareAppointment>[];
      final data = RecordExportData(
        options: options,
        period: period,
        clock: clock,
        plans: plans,
        medicalFile: options.patient ? state.medicalFile : null,
        doses: options.medications ? await dosesIn(period) : const [],
        extraDoses: options.medications ? await extraDosesIn(period) : const [],
        readings: options.measurements
            ? await readingsIn(period, clock)
            : const [],
        measurementTasks: options.measurements
            ? await chunked(period, measurements.occurrences)
            : const [],
        appointments: appointments,
        visits: options.appointments
            ? await visitPapersOf(appointments)
            : const <String, VisitPaper>{},
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
}

enum RecordExportStatus { loading, ready }

/// How far the record export has got, and what it refused.
class RecordExportState extends Equatable {
  const RecordExportState({
    this.status = RecordExportStatus.loading,
    this.medicalFile,
    this.errorKey,
    this.busy = false,
  });

  final RecordExportStatus status;
  final MedicalFile? medicalFile;
  final String? errorKey;

  /// True while the data is read or the file is written and shared.
  final bool busy;

  RecordExportState copyWith({
    RecordExportStatus? status,
    MedicalFile? medicalFile,
    String? errorKey,
    bool clearError = false,
    bool? busy,
  }) => RecordExportState(
    status: status ?? this.status,
    medicalFile: medicalFile ?? this.medicalFile,
    errorKey: clearError ? null : (errorKey ?? this.errorKey),
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [status, medicalFile, errorKey, busy];
}
