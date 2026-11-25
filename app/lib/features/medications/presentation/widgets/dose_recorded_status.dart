import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_lines.dart';
import 'package:flutter/cupertino.dart';

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

/// The sign of what was recorded. The check is knocked out of a filled
/// green disc, so the mark itself is white: a tick that reads at a glance
/// across the card. A dose recorded as not taken gets the quiet minus.
class DoseRecordedMark extends StatelessWidget {
  const DoseRecordedMark({super.key, required this.taken, required this.color});

  final bool taken;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
    taken ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
    color: color,
  );
}
