import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A refused answer's message ([messageKey]), wherever the task is shown.
/// [context] must still be mounted.
void showMeasurementMessage(BuildContext context, String? messageKey) {
  if (messageKey == null) return;
  AppToast.show(context, messageKey, kind: ToastKind.error);
}

/// «تخطي» on [task]: a saved skip confirms, a refused one shows why. The
/// tasks read again by themselves once it is saved.
Future<void> skipMeasurement(
  BuildContext context,
  MeasurementOccurrence task,
) async {
  final draft = await selectSkippedMeasurement(context, task.kind);
  if (draft == null || !context.mounted) return;
  final String? messageKey = await context.read<MeasurementTasksCubit>().skip(
    task,
    draft,
  );
  if (!context.mounted) return;
  if (messageKey != null) return showMeasurementMessage(context, messageKey);
  AppToast.show(context, 'toast.measurement_skipped');
}

/// «قياس السكر» or «قياس الضغط» for [kind].
String measurementKindTitle(BuildContext context, MeasurementKind kind) =>
    context.tr(
      kind == MeasurementKind.glucose
          ? 'measurements.glucose'
          : 'measurements.bp',
    );
