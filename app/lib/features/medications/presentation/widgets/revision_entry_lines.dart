import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_line.dart';
import 'package:app/features/medications/presentation/widgets/revision_fact.dart';
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
