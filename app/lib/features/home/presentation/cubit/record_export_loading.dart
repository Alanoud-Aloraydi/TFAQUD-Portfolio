import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
