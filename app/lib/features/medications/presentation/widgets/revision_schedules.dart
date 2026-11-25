import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

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
