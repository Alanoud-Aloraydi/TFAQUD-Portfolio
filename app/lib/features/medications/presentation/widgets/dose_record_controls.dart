import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoseRecordControls extends StatelessWidget {
  const DoseRecordControls({super.key, required this.occurrence});

  final DoseOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final record = occurrence.record;
    if (record != null) return _RecordedStatus(record: record);
    final isRecording = context.select<MedicationOccurrencesCubit, bool>(
      (cubit) => cubit.state.recordingOccurrence == occurrence,
    );
    if (isRecording) return const _RecordingStatus();
    final today = DateUtils.dateOnly(DateTime.now());
    final scheduledOn = DateUtils.dateOnly(occurrence.scheduledOn);
    if (scheduledOn.isAfter(today)) return const SizedBox.shrink();
    final isToday = scheduledOn == today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isToday) ...[
          FilledButton.icon(
            onPressed: () => _takeNow(context),
            icon: const Icon(Icons.check),
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

class _RecordedStatus extends StatelessWidget {
  const _RecordedStatus({required this.record});

  final DoseRecord record;

  @override
  Widget build(BuildContext context) {
    final taken = record.outcome == DoseOutcome.taken;
    final color = taken
        ? context.tokens.successTint
        : Theme.of(context).colorScheme.errorContainer;
    final ink = taken
        ? context.tokens.successInk
        : Theme.of(context).colorScheme.onErrorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          Icon(taken ? Icons.check_circle : Icons.remove_circle, color: ink),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.tr(
              taken ? 'medications.taken_status' : 'medications.skipped_status',
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}
