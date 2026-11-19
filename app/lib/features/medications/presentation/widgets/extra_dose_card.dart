import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_lines.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_outcome.dart';
import 'package:flutter/material.dart';

/// An extra dose in «سجل الجرعات», drawn as the other doses are: the time
/// it was taken above the medicine with its strength and dose, and in the
/// corner «إضافية» with who recorded it.
class ExtraDoseCard extends StatelessWidget {
  const ExtraDoseCard({super.key, required this.entry, this.circleId});

  final ExtraDoseEntry entry;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: ExtraDoseLines(entry: entry)),
            const SizedBox(width: AppSpacing.sm),
            ExtraDoseOutcome(dose: entry.dose, circleId: circleId),
          ],
        ),
      ),
    ),
  );
}
