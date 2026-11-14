import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_revision_entry.dart';
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
