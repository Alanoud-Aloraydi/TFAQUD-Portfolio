import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/material.dart';

/// What the Today card calls its dose: «حان موعد», «تأخّرت», or the next
/// one due, in the words of whoever is reading.
class TodayDoseTitle extends StatelessWidget {
  const TodayDoseTitle({
    super.key,
    required this.status,
    required this.circleId,
  });

  final DoseTimingState? status;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    return Text(
      CareVoice.tr(context, circleId, switch (status) {
        DoseTimingState.due => 'today_dashboard.due_title',
        DoseTimingState.late => 'today_dashboard.late_title',
        _ => 'today_dashboard.next_dose',
      }),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: AppSemanticColors.textSupporting),
    );
  }
}
