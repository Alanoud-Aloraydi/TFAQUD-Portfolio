import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/attention_medication_lines.dart';
import 'package:app/features/medications/presentation/widgets/dose_controls_layout.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:flutter/material.dart';

/// A dose of «يحتاج انتباهك»: what it was and when, over the buttons that
/// record it late.
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AttentionMedicationLines(
            occurrence: occurrence,
            circleId: circleId,
            canManage: canManage,
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
