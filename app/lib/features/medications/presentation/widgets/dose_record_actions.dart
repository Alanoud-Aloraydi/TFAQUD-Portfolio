import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_answer.dart';
import 'package:app/features/medications/presentation/widgets/dose_skip_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «أُخذت»: records [occurrence] as taken at this moment. [circleId] picks
/// the words of the confirmation.
Future<void> takeDoseNow(
  BuildContext context,
  DoseOccurrence occurrence, {
  String? circleId,
}) async {
  final String? messageKey = await context
      .read<MedicationOccurrencesCubit>()
      .take(occurrence);
  if (context.mounted) {
    showDoseAnswer(context, messageKey, circleId, taken: true);
  }
}

/// Asks when the dose was taken, then records it at that time. [circleId]
/// picks the words of the question.
Future<void> takeDoseAtDifferentTime(
  BuildContext context,
  DoseOccurrence occurrence, {
  String? circleId,
}) async {
  final takenAt = await selectTakenTime(
    context,
    occurrence.scheduledOn,
    circleId: circleId,
  );
  if (takenAt == null || !context.mounted) return;
  final String? messageKey = await context
      .read<MedicationOccurrencesCubit>()
      .take(occurrence, takenAt);
  if (context.mounted) {
    showDoseAnswer(context, messageKey, circleId, taken: true);
  }
}

/// «تخطي»: asks why (optional), then records the dose as not taken.
/// [circleId] picks the words of the confirmation.
Future<void> skipDose(
  BuildContext context,
  DoseOccurrence occurrence, {
  String? circleId,
}) async {
  final draft = await selectSkippedDose(context);
  if (draft == null || !context.mounted) return;
  final String? messageKey = await context
      .read<MedicationOccurrencesCubit>()
      .record(occurrence, draft);
  if (context.mounted) {
    showDoseAnswer(context, messageKey, circleId, taken: false);
  }
}
