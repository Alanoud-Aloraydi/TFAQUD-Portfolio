import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported record export status values.
enum RecordExportStatus { loading, ready }

/// Holds the record export presentation state.
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
