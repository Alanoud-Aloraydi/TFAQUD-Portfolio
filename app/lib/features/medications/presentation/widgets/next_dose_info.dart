import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/next_dose_clock.dart';
import 'package:app/features/medications/presentation/widgets/next_dose_lines.dart';
import 'package:flutter/material.dart';

/// The next dose of «اليوم»: its time, large, beside the medicine and how
/// much to take.
class NextDoseInfo extends StatelessWidget {
  const NextDoseInfo({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NextDoseClock(time: occurrence.time),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: NextDoseLines(
            occurrence: occurrence,
            circleId: circleId,
            canManage: canManage,
          ),
        ),
      ],
    );
  }
}
