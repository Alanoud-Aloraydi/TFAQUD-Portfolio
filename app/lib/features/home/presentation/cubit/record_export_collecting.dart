import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/home/presentation/cubit/record_export_chunks.dart';
import 'package:app/features/home/presentation/cubit/record_export_reads.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
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
