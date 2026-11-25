import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Displays the medication revision history UI.
class MedicationRevisionHistory extends StatelessWidget {
  const MedicationRevisionHistory({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final history = plan.history.isEmpty ? [plan.version] : plan.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('medications.revision_history'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = history.length - 1; index >= 0; index--) ...[
          MedicationRevisionEntry(
            version: history[index],
            previous: index == 0 ? null : history[index - 1],
          ),
          if (index > 0) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// One version of a medicine in «سجل التعديلات»: the day it took over and
/// what the medicine was then, the schedule it replaced crossed out.
class MedicationRevisionEntry extends StatelessWidget {
  const MedicationRevisionEntry({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) => MedicationVersionCard(
    title: context.tr(
      previous == null
          ? 'medications.initial_version'
          : 'medications.revised_on',
      args: <String>[formatMedicationDate(context, version.effectiveFromOn)],
    ),
    version: version,
    previous: previous,
  );
}
