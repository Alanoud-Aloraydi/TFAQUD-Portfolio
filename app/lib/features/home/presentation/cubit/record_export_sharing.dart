import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
