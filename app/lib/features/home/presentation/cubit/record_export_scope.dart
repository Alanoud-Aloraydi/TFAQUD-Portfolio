import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What an export of the record reads and shares with, for one circle.
mixin RecordExportScope on Cubit<RecordExportState> {
  CirclesUseCase get circles;
  RecordExporter get exporter;
  MeasurementsUseCase get measurements;
  MedicationsUseCase get medications;
  AppointmentsUseCase get appointments;
  VisitsUseCase get visits;
  String get circleId;
}
