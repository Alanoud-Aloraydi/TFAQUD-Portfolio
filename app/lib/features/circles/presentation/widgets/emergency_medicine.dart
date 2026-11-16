import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicine_name.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicine_times.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:flutter/material.dart';

/// One medicine on the emergency card: what it is at the start, when it is
/// taken at the end.
class EmergencyMedicine extends StatelessWidget {
  const EmergencyMedicine({super.key, required this.plan, required this.words});

  final MedicationPlan plan;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppSemanticColors.textSupporting);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: EmergencyMedicineName(
                plan: plan,
                words: words,
                small: small,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            EmergencyMedicineTimes(plan: plan, words: words, small: small),
          ],
        ),
      ),
    );
  }
}
