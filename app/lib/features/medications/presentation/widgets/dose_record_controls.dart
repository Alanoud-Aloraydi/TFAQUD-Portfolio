import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/loading_widget.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Defines the supported dose controls layout values.
enum DoseControlsLayout { regular, today, attention }

/// Displays the dose record controls UI.
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
    final record = occurrence.record;
    if (record != null) {
      return _RecordedStatus(occurrence: occurrence, circleId: circleId);
    }
    final isRecording = context.select<MedicationOccurrencesCubit, bool>(
      (cubit) => cubit.state.recordingOccurrence == occurrence,
    );
    if (isRecording) return const _RecordingStatus();
    final today = riyadhToday();
    final scheduledOn = scheduleDay(occurrence.scheduledOn);
    if (scheduledOn.isAfter(today)) return const SizedBox.shrink();
    final isToday = scheduledOn == today;
    if (layout != DoseControlsLayout.regular) {
      final height = layout == DoseControlsLayout.attention ? 34.0 : 44.0;
      return Row(
        children: [
          if (isToday) ...[
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  minimumSize: Size(0, height),
                ),
                onPressed: () => _takeNow(context),
                icon: const Icon(CupertinoIcons.checkmark, size: 16),
                label: Text(context.tr('medications.taken_short')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AppSemanticColors.surfaceContent,
                foregroundColor: AppSemanticColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size(0, height),
              ),
              onPressed: () => _takeAtDifferentTime(context),
              icon: const Icon(CupertinoIcons.clock, size: 16),
              label: Text(context.tr('medications.different_time_short')),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            onPressed: () => _skip(context),
            icon: const Icon(CupertinoIcons.minus_circle, size: 16),
            label: Text(context.tr('medications.skip_short')),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isToday) ...[
          FilledButton.icon(
            onPressed: () => _takeNow(context),
            icon: const Icon(CupertinoIcons.checkmark),
            label: Text(context.tr('medications.taken_now_action')),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        OutlinedButton(
          onPressed: () => _takeAtDifferentTime(context),
          child: Text(context.tr('medications.different_time_action')),
        ),
        TextButton(
          onPressed: () => _skip(context),
          child: Text(context.tr('medications.skip_action')),
        ),
      ],
    );
  }

  Future<void> _takeNow(BuildContext context) =>
      _recordTaken(context, DateTime.now());

  Future<void> _takeAtDifferentTime(BuildContext context) async {
    final takenAt = await selectTakenTime(context, occurrence.scheduledOn);
    if (takenAt == null || !context.mounted) return;
    if (takenAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('medications.future_taken_time'))),
      );
      return;
    }
    await _recordTaken(context, takenAt);
  }

  Future<void> _recordTaken(BuildContext context, DateTime takenAt) async {
    await context.read<MedicationOccurrencesCubit>().record(
      occurrence,
      DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt),
    );
  }

  Future<void> _skip(BuildContext context) async {
    final draft = await selectSkippedDose(context);
    if (draft == null || !context.mounted) return;
    await context.read<MedicationOccurrencesCubit>().record(occurrence, draft);
  }
}

/// Renders the recording status element of dose record controls.
class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus();

  @override
  Widget build(BuildContext context) {
    final label = context.tr('medications.recording_dose');
    return Semantics(
      label: label,
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

/// Renders the recorded status element of dose record controls.
class _RecordedStatus extends StatelessWidget {
  const _RecordedStatus({required this.occurrence, this.circleId});

  final DoseOccurrence occurrence;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final record = occurrence.record!;
    final taken = record.outcome == DoseOutcome.taken;
    // Care status map: taken is success; recorded as not taken is neutral,
    // never an error. The icon keeps its color; the word follows the
    // contrast setting.
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
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          Icon(
            taken
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.minus_circle,
            color: iconColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    taken
                        ? occurrence.takenLate
                              ? 'medications.taken_late_status'
                              : 'medications.taken_status'
                        : 'medications.skipped_status',
                  ),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: ink),
                ),
                if (record.takenAt case final takenAt?)
                  Text(
                    context.tr(
                      'medications.recorded_at',
                      args: [_takenTime(context, takenAt)],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (circleId case final circleId?)
                  if (record.recordedByName case final name?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PersonPhoto(
                          name: name,
                          photoPath: personPhotoPath(
                            circleId,
                            record.recordedByAccountId,
                          ),
                          avatarCode: record.recordedByAvatarCode,
                          size: AppSizes.iconSmall,
                        ),
                        const SizedBox(width: AppSpacing.tight),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _takenTime(BuildContext context, DateTime takenAt) {
    final local = riyadhNow(takenAt);
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return formatMedicationTime(context, time);
  }
}
