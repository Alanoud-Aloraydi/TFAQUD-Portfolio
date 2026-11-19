import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
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
