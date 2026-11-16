import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/revision_entry_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One version of a medicine in «التعديلات»: the day it took over, what
/// the medicine was then, and the schedule it replaced, crossed out.
class MedicationRevisionEntry extends StatelessWidget {
  const MedicationRevisionEntry({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: MergeSemantics(
        child: RevisionEntryLines(
          title: context.tr(
            previous == null
                ? 'medications.initial_version'
                : 'medications.revised_on',
            args: [formatMedicationDate(context, version.effectiveFromOn)],
          ),
          version: version,
          previous: previous,
        ),
      ),
    );
  }
}
