import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «أقدم» under «سجل الجرعات»: reads the days before, not before
/// [earliest]; off while they are being read.
class DoseHistoryEarlier extends StatelessWidget {
  const DoseHistoryEarlier({
    super.key,
    required this.state,
    required this.earliest,
  });

  final MedicationOccurrencesState state;
  final DateTime earliest;

  /// The button while there are days left to read, otherwise null.
  static Widget? orNull(
    BuildContext context,
    MedicationOccurrencesState state,
    DateTime earliest,
  ) => context.read<MedicationOccurrencesCubit>().canLoadEarlier(earliest)
      ? DoseHistoryEarlier(state: state, earliest: earliest)
      : null;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: state.status == MedicationOccurrencesStatus.loadingMore
          ? null
          : () => context.read<MedicationOccurrencesCubit>().loadEarlier(
              earliest,
            ),
      child: Text(context.tr('medications.load_earlier')),
    ),
  );
}

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
