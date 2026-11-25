import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_text.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
import 'package:flutter/material.dart';

/// A late dose of «يحتاج انتباهك»: the pill, then the three lines, read in
/// one breath and opening with the medicine, and tapped to open it.
class AttentionMedicationLines extends StatelessWidget {
  const AttentionMedicationLines({
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
    final String dose = formatMedicationDose(
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AttentionDosePill(circleId: circleId, planId: occurrence.planId),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: MergeSemantics(
            child: Semantics(
              button: true,
              label: spoken('$title، $when، $how'),
              child: InkWell(
                onTap: () =>
                    openMedication(context, circleId, occurrence, canManage),
                child: ExcludeSemantics(
                  child: AttentionDoseText(title: title, when: when, how: how),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The medicine's photo beside a late dose, or a pill while it has none. It
/// is decoration; the name says what it is.
class AttentionDosePill extends StatelessWidget {
  const AttentionDosePill({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MedicationPhotoCircle(
        circleId: circleId,
        planId: planId,
        size: 34,
        fallback: CircleAvatar(
          radius: 17,
          backgroundColor: context.tokens.error.withValues(alpha: .08),
          child: Icon(
            TafaqodPhosphorIcons.pill,
            color: context.tokens.error,
            size: 18,
          ),
        ),
      ),
    );
  }
}
