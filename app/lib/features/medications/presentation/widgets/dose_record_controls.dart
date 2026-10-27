import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
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
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _take(context),
            icon: const Icon(Icons.check),
            label: Text(context.tr('medications.taken_action')),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _skip(context),
            child: Text(context.tr('medications.skip_action')),
          ),
        ),
      ],
    );
  }

  Future<void> _take(BuildContext context) async {
    final takenAt = await selectTakenTime(context, occurrence.scheduledOn);
    if (takenAt == null || !context.mounted) return;
    await context.read<MedicationOccurrencesCubit>().record(
      occurrence,
      DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt),
    );
  }

  Future<void> _skip(BuildContext context) async {
    final confirmed = await confirmSkippedDose(context);
    if (!confirmed || !context.mounted) return;
    await context.read<MedicationOccurrencesCubit>().record(
      occurrence,
      const DoseRecordDraft(outcome: DoseOutcome.skipped),
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
