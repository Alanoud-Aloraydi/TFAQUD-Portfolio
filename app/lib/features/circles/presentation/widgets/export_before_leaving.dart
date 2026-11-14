import 'package:app/core/errors/failure.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:multiple_result/multiple_result.dart';

/// Opens the record export with what this circle has, so its data can be
/// taken out before the circle goes. The circle is not left: the person
/// taps «مغادرة الدائرة» again once the file is saved.
Future<void> exportBeforeLeaving(BuildContext context, String circleId) async {
  final Result<List<MedicationPlan>, Failure> plans = await GetIt.I
      .get<MedicationsUseCase>()
      .getPlans(circleId);
  final List<MeasurementPlan> measurementPlans = await GetIt.I
      .get<MeasurementsUseCase>()
      .plans(circleId);
  if (!context.mounted) return;
  final Failure? failure = plans.tryGetError();
  if (failure != null) {
    AppToast.show(context, failure.messageKey, kind: ToastKind.error);
    return;
  }
  await showRecordExportSheet(
    context,
    circleId: circleId,
    plans: plans.tryGetSuccess()!,
    measurementPlans: measurementPlans,
  );
}
