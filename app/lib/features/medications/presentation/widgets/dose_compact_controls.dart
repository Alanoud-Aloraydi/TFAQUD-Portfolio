import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_compact_button_styles.dart';
import 'package:app/features/medications/presentation/widgets/dose_compact_primary_row.dart';
import 'package:app/features/medications/presentation/widgets/dose_compact_secondary_row.dart';
import 'package:flutter/material.dart';

/// The answers to one unrecorded dose where the row is tight (a today row
/// or an attention card): two lines of equal buttons, one finger high.
Widget doseCompactControls(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required bool isToday,
  String? circleId,
}) {
  final ButtonStyle compact = doseCompactFilledStyle();
  final ButtonStyle compactText = doseCompactTextStyle();
  final bool canSnooze = isToday && circleId != null;
  // The two answers first («انأخذت», «ذكّرني لاحقًا»), then the two
  // less common ones as text buttons, so no label wraps.
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: doseCompactPrimaryRow(
          context,
          occurrence: occurrence,
          compact: compact,
          isToday: isToday,
          canSnooze: canSnooze,
          circleId: circleId,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      // The second line matches the first: two buttons of one height,
      // each taking half the row. Sized to their words they came out
      // three different widths under two equal ones.
      Row(
        children: doseCompactSecondaryRow(
          context,
          occurrence: occurrence,
          compactText: compactText,
          isToday: isToday,
          circleId: circleId,
        ),
      ),
    ],
  );
}
