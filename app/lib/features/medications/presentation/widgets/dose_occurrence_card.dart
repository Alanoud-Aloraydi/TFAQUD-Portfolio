import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_lines.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:flutter/material.dart';

/// One dose in a medicine's history: its time and timing, the medicine and
/// dose, and who recorded it.
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DoseOccurrenceLines(occurrence: occurrence),
            if (occurrence.record != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              DoseRecordControls(occurrence: occurrence, circleId: circleId),
            ],
          ],
        ),
      ),
    );
  }
}
