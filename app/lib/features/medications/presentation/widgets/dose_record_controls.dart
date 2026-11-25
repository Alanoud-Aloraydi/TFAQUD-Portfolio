import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/loading/loading_widget.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_task_buttons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The answers to one unrecorded dose («تم أخذها», another time, skip,
/// «ذكّرني لاحقًا»), or its recorded status. Calls the nearest
/// [MedicationOccurrencesCubit] and shows a refused answer's message.
class DoseRecordControls extends StatelessWidget {
  const DoseRecordControls({
    super.key,
    required this.occurrence,
    this.layout = DoseControlsLayout.regular,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final DoseControlsLayout layout;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    if (occurrence.record != null) {
      return DoseRecordedStatus(occurrence: occurrence, circleId: circleId);
    }
    final isRecording = context.select<MedicationOccurrencesCubit, bool>(
      (cubit) => cubit.state.recordingOccurrence == occurrence,
    );
    if (isRecording) return const DoseRecordingStatus();
    final today = PatientClockScope.of(context).today();
    final scheduledOn = scheduleDay(occurrence.scheduledOn);
    if (scheduledOn.isAfter(today)) return const SizedBox.shrink();
    final isToday = scheduledOn == today;
    if (layout != DoseControlsLayout.regular) {
      return DoseTaskButtons(
        occurrence: occurrence,
        isToday: isToday,
        circleId: circleId,
      );
    }
    return doseRegularControls(
      context,
      occurrence: occurrence,
      isToday: isToday,
      circleId: circleId,
    );
  }
}

/// Renders the recording status element of dose record controls.
class DoseRecordingStatus extends StatelessWidget {
  const DoseRecordingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final label = context.tr('medications.recording_dose');
    return Semantics(
      label: spoken(label),
      liveRegion: true,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingWidget(size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// What the buttons become once the dose is answered: the answer itself,
/// in a box of its own colour.
///
/// Care status map: taken is success; recorded as not taken is neutral,
/// never an error. The block held the page's own background and no edge, so
/// it melted into the card around it. An edge in the colour of its own
/// answer closes it: green for a dose taken, a quiet grey for one recorded
/// as not taken, which is a fact and not a fault.
class DoseRecordedStatus extends StatelessWidget {
  const DoseRecordedStatus({
    super.key,
    required this.occurrence,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final bool taken = occurrence.record!.outcome == DoseOutcome.taken;
    // The icon keeps its colour; the word follows the contrast setting.
    final Color iconColor = taken
        ? context.tokens.success
        : context.tokens.textSecondary;
    final Color ink = taken
        ? context.tokens.successText
        : context.tokens.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        border: Border.all(
          color: taken ? iconColor : AppSemanticColors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          DoseRecordedMark(taken: taken, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: doseRecordedLines(
                context,
                occurrence: occurrence,
                ink: ink,
                circleId: circleId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sign of what was recorded. The check is knocked out of a filled
/// green disc, so the mark itself is white: a tick that reads at a glance
/// across the card. A dose recorded as not taken gets the quiet minus.
class DoseRecordedMark extends StatelessWidget {
  const DoseRecordedMark({super.key, required this.taken, required this.color});

  final bool taken;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
    taken ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
    color: color,
  );
}

/// The words inside a recorded dose's box: what was recorded, when, why it
/// was skipped, and who answered it. [ink] colours the first line.
List<Widget> doseRecordedLines(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required Color ink,
  String? circleId,
}) {
  final DoseRecord record = occurrence.record!;
  final bool taken = record.outcome == DoseOutcome.taken;
  return <Widget>[
    // The patient reads «تم تسجيل إنك أخذت الجرعة»; someone
    // caring for them reads the patient's name instead.
    Text(
      CareVoice.tr(
        context,
        circleId,
        taken
            ? occurrence.isTakenLate(PatientClockScope.of(context))
                  ? 'medications.taken_late_status'
                  : 'medications.taken_status'
            : 'medications.skipped_status',
      ),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ink),
    ),
    if (record.takenAt case final takenAt?)
      Text(
        context.tr(
          'medications.recorded_at',
          args: [_takenTime(context, takenAt)],
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    if (!taken && record.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: [doseSkipReasonText(context, record)],
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ...doseRecorderLine(context, record: record, circleId: circleId),
  ];
}

String _takenTime(BuildContext context, DateTime takenAt) {
  return wallTimeText(PatientClockScope.of(context).wallTime(takenAt));
}

/// Who answered a recorded dose, with their photo beside the name. Shown
/// only inside a circle ([circleId]) and only once the server sent a name,
/// so a dose from before this was tracked keeps its three lines.
List<Widget> doseRecorderLine(
  BuildContext context, {
  required DoseRecord record,
  String? circleId,
}) {
  if (circleId == null) return const <Widget>[];
  final String? name = record.recordedByName;
  if (name == null) return const <Widget>[];
  return <Widget>[
    const SizedBox(height: AppSpacing.xs),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonPhoto(
          name: name,
          photoPath: personPhotoPath(circleId, record.recordedByAccountId),
          avatarCode: record.recordedByAvatarCode,
          size: AppSizes.iconSmall,
        ),
        const SizedBox(width: AppSpacing.tight),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  ];
}
