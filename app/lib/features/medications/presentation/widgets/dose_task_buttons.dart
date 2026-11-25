import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/skip_reason_sheet.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/snooze_ruler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One button system for every task (TaskButtonRole): «تم أخذها» across the
/// card, then «ذكّرني لاحقًا» and «تخطي» under it.
///
/// «تم أخذها» asks when the dose was taken and offers the moment it is
/// pressed, so the one button records a dose taken now and one taken
/// earlier; «تم أخذها في وقت سابق» was a button of its own before, and a dose
/// of an earlier day had no way to be marked taken now. «ذكّرني لاحقًا»
/// is only for a dose of today: a day that has passed cannot be put off.
class DoseTaskButtons extends StatelessWidget {
  const DoseTaskButtons({
    super.key,
    required this.occurrence,
    required this.isToday,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final bool isToday;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    String say(String key) => CareVoice.tr(context, circleId, key);
    return TaskButtonGrid(
      // A day of four doses shows four «تم أخذها»: read aloud they are the
      // same word, so the reader is told which medicine.
      answer: TaskButton(
        role: TaskButtonRole.answer,
        icon: CupertinoIcons.checkmark,
        label: say('medications.taken_short'),
        semanticLabel: '${say('medications.taken_short')}، ${occurrence.name}',
        onPressed: () =>
            takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
      ),
      choices: <Widget>[
        if (isToday && circleId != null)
          SnoozeButton(occurrence: occurrence, circleId: circleId!),
        TaskButton(
          role: TaskButtonRole.skip,
          icon: CupertinoIcons.minus_circle,
          label: context.tr('medications.skip_short'),
          onPressed: () => skipDose(context, occurrence, circleId: circleId),
        ),
      ],
    );
  }
}

/// The answers to one unrecorded dose where there is room for them: a
/// full-width button a line.
Widget doseRegularControls(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required bool isToday,
  String? circleId,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (isToday) ...[
        FilledButton.icon(
          onPressed: () => takeDoseNow(context, occurrence, circleId: circleId),
          icon: const Icon(CupertinoIcons.checkmark),
          label: Text(
            CareVoice.tr(context, circleId, 'medications.taken_now_action'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      OutlinedButton(
        onPressed: () =>
            takeDoseAtDifferentTime(context, occurrence, circleId: circleId),
        child: Text(context.tr('medications.different_time_action')),
      ),
      TextButton(
        onPressed: () => skipDose(context, occurrence, circleId: circleId),
        child: Text(context.tr('medications.skip_action')),
      ),
    ],
  );
}

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

/// Asks when the dose of [scheduledOn] was taken and returns that moment.
/// The time picked is the patient's wall clock on that day, wherever this
/// phone is; the wheel starts at now on that clock.
///
/// [circleId] picks the words: «متى أخذت الجرعة؟» for the patient, «متى تم
/// أخذ الجرعة؟» for someone caring for them ([CareVoice]).
Future<DateTime?> selectTakenTime(
  BuildContext context,
  DateTime scheduledOn, {
  String? circleId,
}) async {
  final PatientClock clock = PatientClockScope.of(context);
  final selected = await showTafaqodTimeSheet(
    context,
    initialTime: TimeOfDay.fromDateTime(clock.now()),
    title: CareVoice.tr(context, circleId, 'medications.actual_time'),
  );
  if (selected == null) return null;
  return clock.momentOf(scheduledOn, '${selected.hour}:${selected.minute}');
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
void showDoseAnswer(
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

/// Asks why the dose is skipped (optional) with the app's one skip sheet,
/// and returns the skipped record to save; null when the sheet is closed.
Future<DoseRecordDraft?> selectSkippedDose(BuildContext context) async {
  final SkipReasonChoice? choice = await showSkipReasonSheet(
    context,
    title: context.tr('medications.skip_title'),
    message: context.tr('medications.skip_reason_optional'),
    reasons: <SkipReasonOption>[
      for (final DoseSkipReason reason in DoseSkipReason.values)
        SkipReasonOption(
          reason.apiValue,
          context.tr('medications.skip_reason.${reason.name}'),
        ),
    ],
    noteLabel: context.tr('medications.skip_reason_note'),
    confirmLabel: context.tr('medications.skip_confirm'),
  );
  if (choice == null) return null;
  return DoseRecordDraft(
    outcome: DoseOutcome.skipped,
    skipReasonCode: choice.code,
    skipReasonNote: choice.note,
  );
}
