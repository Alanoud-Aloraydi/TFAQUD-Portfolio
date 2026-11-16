import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
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
  if (context.mounted) _answer(context, messageKey, circleId, taken: true);
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
  if (context.mounted) _answer(context, messageKey, circleId, taken: true);
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
  if (context.mounted) _answer(context, messageKey, circleId, taken: false);
}

/// A refused answer's message ([messageKey]), wherever the controls are.
/// [context] must still be mounted.
void showDoseRefusal(BuildContext context, String? messageKey) {
  if (messageKey == null) return;
  AppToast.show(context, messageKey, kind: ToastKind.error);
}

/// What the person sees once the record is written: the refusal when the
/// server turned it down, otherwise the confirmation that it was saved —
/// a recorded dose changes little on screen, so silence would leave the
/// person unsure whether it reached the record.
void _answer(
  BuildContext context,
  String? messageKey,
  String? circleId, {
  required bool taken,
}) {
  if (messageKey != null) return showDoseRefusal(context, messageKey);
  AppToast.showText(
    ScaffoldMessenger.of(context),
    CareVoice.tr(
      context,
      circleId,
      taken ? 'medications.taken_status' : 'medications.skipped_status',
    ),
  );
}
