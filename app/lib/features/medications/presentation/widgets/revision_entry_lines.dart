import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_summary.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What one version says: what the medicine was, and the schedule it took
/// over from, crossed out when it changed.
class RevisionEntryLines extends StatelessWidget {
  const RevisionEntryLines({
    super.key,
    required this.title,
    required this.version,
    required this.previous,
  });

  final String title;
  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? before = previous == null
        ? null
        : medicationScheduleSummary(context, previous!.schedules);
    final String after = medicationScheduleSummary(context, version.schedules);
    final String what = medicationVersionLine(context, version);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(what, style: text.bodyMedium, semanticsLabel: spoken(what)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('medications.schedule_revision'),
          style: text.bodySmall,
        ),
        if (before != null && before != after)
          Text(
            before,
            style: text.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(after, style: text.bodyMedium),
        if (version.reason case final reason?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(reason, style: text.bodySmall),
        ],
        if (version.instructions case final instructions?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(instructions, style: text.bodySmall),
        ],
      ],
    );
  }
}
