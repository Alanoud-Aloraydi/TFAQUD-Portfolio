import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_chunks.dart';
import 'package:app/features/home/presentation/cubit/record_export_collecting.dart';
import 'package:app/features/home/presentation/cubit/record_export_loading.dart';
import 'package:app/features/home/presentation/cubit/record_export_reads.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/home/presentation/cubit/record_export_sharing.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
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
