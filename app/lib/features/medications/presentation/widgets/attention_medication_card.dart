import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AttentionMedicationCard extends StatelessWidget {
  const AttentionMedicationCard({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final String title =
        '${occurrence.name} ${doseStrengthText(context, occurrence)}';
    final String when =
        '${formatMedicationDate(context, occurrence.scheduledOn)}'
        '، ${clockText(occurrence.time)}';
    final String how = occurrence.instructions == null
        ? dose
        : '$dose، ${occurrence.instructions}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The pill is decoration; the name says what it is.
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: context.tokens.error.withValues(alpha: .08),
                  child: Icon(
                    TafaqodPhosphorIcons.pill,
                    color: context.tokens.error,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Expanded(
                // One node for the three lines, read in one breath and
                // opening with the medicine.
                child: MergeSemantics(
                  child: Semantics(
                    button: true,
                    label: spoken('$title، $when، $how'),
                    child: InkWell(
                      onTap: () => context.push(
                        Routes.medicationDetails(circleId, occurrence.planId),
                        extra: canManage,
                      ),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              when,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              how,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DoseRecordControls(
            occurrence: occurrence,
            layout: DoseControlsLayout.attention,
            circleId: circleId,
          ),
        ],
      ),
    );
  }
}
