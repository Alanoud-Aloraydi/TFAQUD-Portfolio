import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// [entries], newest first, under the date of their day: the doses of the
/// dose times and the extra doses, each in the same card.
class DoseHistoryDays extends StatelessWidget {
  const DoseHistoryDays({
    super.key,
    required this.entries,
    required this.circleId,
  });

  final List<DoseHistoryEntry> entries;

  /// Needed to show who recorded each dose.
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<DoseHistoryEntry>> days =
        <DateTime, List<DoseHistoryEntry>>{};
    for (final DoseHistoryEntry item in entries) {
      final DateTime day = DateUtils.dateOnly(item.day);
      days.putIfAbsent(day, () => <DoseHistoryEntry>[]).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<DateTime, List<DoseHistoryEntry>> day
            in days.entries) ...<Widget>[
          Text(
            formatMedicationDate(context, day.key),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final DoseHistoryEntry item in day.value) ...<Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: switch (item) {
                  ScheduledDoseEntry(:final occurrence) => DoseOccurrenceCard(
                    occurrence: occurrence,
                    circleId: circleId,
                  ),
                  ExtraDoseEntry() => ExtraDoseCard(
                    entry: item,
                    circleId: circleId,
                  ),
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// One dose in a medicine's history, read as one sentence: its time right
/// above the medicine with its strength and dose beside the name, and in
/// the corner what became of it with who recorded it, as on «جدول اليوم».
class DoseOccurrenceCard extends StatelessWidget {
  const DoseOccurrenceCard({
    super.key,
    required this.occurrence,
    this.circleId,
  });

  final DoseOccurrence occurrence;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final DoseRowStatus? status = occurrence.record == null
        ? null
        : DoseRowStatus.of(
            context,
            occurrence,
            PatientClockScope.of(context).now(),
          );
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: DoseOccurrenceLines(
                  occurrence: occurrence,
                  status: status,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DoseHistoryOutcome(
                occurrence: occurrence,
                status: status,
                circleId: circleId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An extra dose in «سجل الجرعات», drawn as the other doses are: the time
/// it was taken above the medicine with its strength and dose, and in the
/// corner «إضافية» with who recorded it.
class ExtraDoseCard extends StatelessWidget {
  const ExtraDoseCard({super.key, required this.entry, this.circleId});

  final ExtraDoseEntry entry;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: ExtraDoseLines(entry: entry)),
            const SizedBox(width: AppSpacing.sm),
            ExtraDoseOutcome(dose: entry.dose, circleId: circleId),
          ],
        ),
      ),
    ),
  );
}

/// The corner of an extra dose in the history, where the other doses say
/// what became of them: «إضافية», with who recorded it centred under it.
class ExtraDoseOutcome extends StatelessWidget {
  const ExtraDoseOutcome({super.key, required this.dose, this.circleId});

  final ExtraDose dose;

  /// Needed to show who recorded it; null leaves the pill alone.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final String? name = dose.recordedByName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        StatusBadge(
          text: context.tr('medications.extra_dose_badge'),
          tone: StatusTone.info,
        ),
        if ((circleId, name) case (final String circle, final String who))
          RecorderLine(
            name: who,
            photoPath: personPhotoPath(circle, dose.recordedByAccountId),
            avatarCode: dose.recordedByAvatarCode,
            large: true,
          ),
      ],
    );
  }
}

/// The words of a dose in the history: its time right above the medicine,
/// whose strength and dose sit beside its name in small pills, then the
/// note, then how late it was taken or why it was skipped.
class DoseOccurrenceLines extends StatelessWidget {
  const DoseOccurrenceLines({super.key, required this.occurrence, this.status});

  final DoseOccurrence occurrence;

  /// Its pill as «جدول اليوم» says it; null while nobody recorded it.
  final DoseRowStatus? status;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DoseHistoryHeading(occurrence: occurrence),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(occurrence.name, style: text.titleMedium),
            for (final String fact in <String>[
              doseStrengthText(context, occurrence),
              formatMedicationDose(
                context,
                occurrence.doseValue,
                occurrence.doseUnit,
              ),
            ])
              FactPill(fact),
          ],
        ),
        if (occurrence.instructions case final String instructions)
          Text(instructions, style: text.bodySmall),
        if ((occurrence.record, status) case (
          final DoseRecord record,
          final DoseRowStatus pill,
        ))
          ...doseHistoryNotes(context, record, pill),
      ],
    );
  }
}

/// The small lines under a recorded dose of the history, the words
/// «جدول اليوم» uses: how long after its time it was taken, and why a
/// skipped dose was not taken.
List<Widget> doseHistoryNotes(
  BuildContext context,
  DoseRecord record,
  DoseRowStatus status,
) {
  final TextStyle? small = Theme.of(context).textTheme.bodySmall;
  return <Widget>[
    if (status.lateBy case final String lateBy) Text(lateBy, style: small),
    if (record.outcome == DoseOutcome.skipped && record.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: <String>[doseSkipReasonText(context, record)],
        ),
        style: small,
      ),
  ];
}
