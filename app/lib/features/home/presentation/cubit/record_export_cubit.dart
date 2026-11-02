import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum RecordExportStatus { loading, ready }

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
  RecordExportCubit(this._circles, this._exporter, this.circleId)
    : super(const RecordExportState());

  final CirclesUseCase _circles;
  final RecordPdfExporter _exporter;
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

  /// [pageLabel] writes «صفحة 1 من 2» for the footer of each page.
  Future<String?> share({
    required String title,
    required String subtitle,
    required String appName,
    required String Function(int page, int pages) pageLabel,
    required List<RecordPdfSection> sections,
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
