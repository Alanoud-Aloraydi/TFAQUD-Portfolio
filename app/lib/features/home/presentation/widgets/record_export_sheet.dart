import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_body.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> showRecordExportSheet(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
  required List<MeasurementPlan> measurementPlans,
}) => showGlassSheet<void>(
  context,
  title: context.tr('record_export.title'),
  message: context.tr('record_export.subtitle'),
  builder: (_) => BlocProvider(
    create: (_) => RecordExportCubit(
      GetIt.I<CirclesUseCase>(),
      GetIt.I<RecordExporter>(),
      GetIt.I<MeasurementsUseCase>(),
      GetIt.I<MedicationsUseCase>(),
      GetIt.I<AppointmentsUseCase>(),
      GetIt.I<VisitsUseCase>(),
      circleId,
    )..load(),
    child: RecordExportSheetBody(
      plans: List.unmodifiable(plans),
      measurementPlans: List.unmodifiable(measurementPlans),
    ),
  ),
);
