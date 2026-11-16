import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/attention_medication_card.dart';
import 'package:flutter/material.dart';

/// The doses of «يحتاج انتباهك», a gap between each. The one a tapped
/// notification is about is brought into view and tinted ([FocusMark]).
class AttentionDoseCards extends StatelessWidget {
  const AttentionDoseCards({
    super.key,
    required this.occurrences,
    required this.circleId,
    required this.canManage,
  });

  final List<DoseOccurrence> occurrences;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      for (final DoseOccurrence item in occurrences) ...<Widget>[
        FocusMark(
          itemKey: doseSnoozeKey(circleId, item),
          radius: AppRadius.field,
          child: AttentionMedicationCard(
            occurrence: item,
            circleId: circleId,
            canManage: canManage,
          ),
        ),
        if (item != occurrences.last) const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}
