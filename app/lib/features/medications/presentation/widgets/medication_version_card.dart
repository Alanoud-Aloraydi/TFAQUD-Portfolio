import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One version of a medicine as a card, the same for every step of «سجل
/// التعديلات» and for the change that waits for its day: the [title], an
/// optional [note] under it, the medicine as [version] has it (what changed
/// from [previous] crossed out), read as one sentence, then an [action].
class MedicationVersionCard extends StatelessWidget {
  const MedicationVersionCard({
    super.key,
    required this.title,
    required this.version,
    required this.previous,
    this.note,
    this.action,
  });

  final String title;
  final MedicationVersion version;
  final MedicationVersion? previous;
  final String? note;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: AppTextTheme.bold,
                  ),
                ),
                if (note case final String note)
                  Text(
                    note,
                    style: text.bodySmall?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                RevisionEntryLines(version: version, previous: previous),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// What one version says, in labelled lines that read at a glance: the
/// medicine, its dose times in soft pills (what changed from [previous]
/// crossed out), why and how it is taken, and when a dose counts as missed.
class RevisionEntryLines extends StatelessWidget {
  const RevisionEntryLines({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) {
    final String what = medicationVersionLine(context, version);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RevisionFact(
          label: context.tr('medications.medicine_label'),
          child: Text(what, semanticsLabel: spoken(what)),
        ),
        RevisionFact(
          label: context.tr('medications.dose_schedules'),
          child: RevisionSchedules(version: version, previous: previous),
        ),
        for (final (String key, String? value) in <(String, String?)>[
          ('medications.reason', version.reason),
          ('medications.instructions', version.instructions),
          (
            'medications.missed_after',
            arabicCount(
              context,
              ArabicCount.minutes,
              version.missedAfterMinutes,
            ),
          ),
        ])
          if (value != null)
            RevisionFact(label: context.tr(key), child: Text(value)),
      ],
    );
  }
}

/// What a medicine was in one version, «ميتفورمين، 500 ملغ، أقراص».
String medicationVersionLine(BuildContext context, MedicationVersion version) =>
    '${version.name}، '
    '${formatMedicationNumber(version.strengthValue)} '
    '${context.tr('medications.strength_display.${version.strengthUnit.name}')}، '
    '${context.tr('medications.form.${version.dosageForm.name}')}';

/// One labelled line of a change in «سجل التعديلات»: a small grey [label]
/// over its [child], as the medicine's own facts read.
class RevisionFact extends StatelessWidget {
  const RevisionFact({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DefaultTextStyle.merge(style: text.bodyLarge, child: child),
        ],
      ),
    );
  }
}

/// The dose times of a change, one soft pill each («8:00 ص، 1 حبة»), and
/// above them, crossed out, the times they took over from when those were
/// different ([previous]).
class RevisionSchedules extends StatelessWidget {
  const RevisionSchedules({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) {
    final String after = medicationScheduleSummary(context, version.schedules);
    final String? before = switch (previous) {
      final MedicationVersion old => medicationScheduleSummary(
        context,
        old.schedules,
      ),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (before != null && before != after)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              before,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.tokens.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final schedule in version.schedules)
              FactPill(medicationScheduleSummary(context, [schedule])),
          ],
        ),
      ],
    );
  }
}

/// A medicine's whole day in one line, «08:00، قرص، 20:00، قرص»: for the
/// boxes that compare one schedule against another and have no room for a
/// list.
String medicationScheduleSummary(
  BuildContext context,
  List<MedicationSchedule> schedules,
) => schedules
    .map(
      (schedule) =>
          '${clockText(schedule.time)}، '
          '${formatMedicationDose(context, schedule.doseValue, schedule.doseUnit)}',
    )
    .join('، ');
