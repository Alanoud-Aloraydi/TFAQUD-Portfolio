import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_lines.dart';
import 'package:flutter/material.dart';

/// One dose in a medicine's history: its time and what became of it with
/// who recorded it, the medicine and dose. What became of it is a pill in
/// the corner, as on «جدول اليوم», not a box of its own under the dose.
class DoseOccurrenceCard extends StatelessWidget {
  const DoseOccurrenceCard({
    super.key,
    required this.occurrence,
    this.circleId,
  });

  final DoseOccurrence occurrence;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: DoseOccurrenceLines(occurrence: occurrence, circleId: circleId),
      ),
    );
  }
}
