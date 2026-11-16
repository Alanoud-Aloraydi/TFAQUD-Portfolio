import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_lines.dart';
import 'package:flutter/cupertino.dart';

/// Renders the recorded status element of dose record controls.
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
    final record = occurrence.record!;
    final taken = record.outcome == DoseOutcome.taken;
    // Care status map: taken is success; recorded as not taken is neutral,
    // never an error. The icon keeps its color; the word follows the
    // contrast setting.
    final Color iconColor = taken
        ? context.tokens.success
        : context.tokens.textSecondary;
    final Color ink = taken
        ? context.tokens.successText
        : context.tokens.textSecondary;
    // The block held the page's own background and no edge, so it melted
    // into the card around it. An edge in the color of its own answer
    // closes it: green for a dose taken, a quiet grey for one recorded as
    // not taken, which is a fact and not a fault.
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
          // The check is knocked out of a filled green disc, so the mark
          // itself is white: a tick that reads at a glance across the card.
          Icon(
            taken
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.minus_circle,
            color: iconColor,
          ),
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
