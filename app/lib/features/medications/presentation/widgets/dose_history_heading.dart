import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/material.dart';

/// The top line of a dose in the history, right above the medicine: its
/// time, or for a dose taken, the time it really was; for an extra dose,
/// [takenAt].
class DoseHistoryHeading extends StatelessWidget {
  const DoseHistoryHeading({super.key, required DoseOccurrence this.occurrence})
    : takenAt = null;

  const DoseHistoryHeading.taken({super.key, required DateTime this.takenAt})
    : occurrence = null;

  final DoseOccurrence? occurrence;
  final DateTime? takenAt;

  @override
  Widget build(BuildContext context) {
    final DateTime? taken = takenAt ?? occurrence?.record?.takenAt;
    return Text(
      taken == null
          ? clockText(occurrence!.time)
          : wallTimeText(PatientClockScope.of(context).wallTime(taken)),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: AppTextTheme.bold,
        color: AppSemanticColors.textPrimary,
      ),
    );
  }
}
