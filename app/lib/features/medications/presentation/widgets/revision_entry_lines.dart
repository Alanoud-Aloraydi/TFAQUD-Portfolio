import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/revision_schedules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
