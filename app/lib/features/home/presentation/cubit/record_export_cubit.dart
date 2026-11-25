import 'package:app/core/errors/failure.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/usecases/visits_use_case.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/repositories/record_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_collecting.dart';
import 'package:app/features/home/presentation/cubit/record_export_reads.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the record for an export and shares the PDF, outside the sheet.
class RecordExportCubit extends Cubit<RecordExportState>
    with
        RecordExportScope,
        RecordExportLoading,
        RecordExportChunks,
        RecordExportReads,
        RecordExportCollecting,
        RecordExportSharing {
  RecordExportCubit(
    this.circles,
    this.exporter,
    this.measurements,
    this.medications,
    this.appointments,
    this.visits,
    this.circleId,
  ) : super(const RecordExportState());

  @override
  final CirclesUseCase circles;
  @override
  final RecordExporter exporter;
  @override
  final MeasurementsUseCase measurements;
  @override
  final MedicationsUseCase medications;
  @override
  final AppointmentsUseCase appointments;
  @override
  final VisitsUseCase visits;
  @override
  final String circleId;
}

/// Reading the medical file the export's patient section is made from.
mixin RecordExportLoading on Cubit<RecordExportState>, RecordExportScope {
  Future<void> load() async {
    final result = await circles.getMedicalFile(circleId);
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
}

/// Sharing the finished PDF of the record.
mixin RecordExportSharing on Cubit<RecordExportState>, RecordExportScope {
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
      await exporter.share(
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
}
