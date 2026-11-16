import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_lines.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_mark.dart';
import 'package:flutter/material.dart';

/// What the buttons become once the dose is answered: the answer itself,
/// in a box of its own colour.
///
/// Care status map: taken is success; recorded as not taken is neutral,
/// never an error. The block held the page's own background and no edge, so
/// it melted into the card around it. An edge in the colour of its own
/// answer closes it: green for a dose taken, a quiet grey for one recorded
/// as not taken, which is a fact and not a fault.
class DoseRecordedStatus extends StatelessWidget {
  const DoseRecordedStatus({
    super.key,
    required this.occurrence,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final bool taken = occurrence.record!.outcome == DoseOutcome.taken;
    // The icon keeps its colour; the word follows the contrast setting.
    final Color iconColor = taken
        ? context.tokens.success
        : context.tokens.textSecondary;
    final Color ink = taken
        ? context.tokens.successText
        : context.tokens.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        border: Border.all(
          color: taken ? iconColor : AppSemanticColors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          DoseRecordedMark(taken: taken, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: doseRecordedLines(
                context,
                occurrence: occurrence,
                ink: ink,
                circleId: circleId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
