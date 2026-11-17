import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_days.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_empty_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The doses that were read, newest first, under the filter of «سجل
/// الجرعات», with «أقدم» under them while there is more to read. Only the
/// doses that had their time: one still ahead is not history yet.
class DoseHistoryView extends StatelessWidget {
  const DoseHistoryView({
    super.key,
    required this.state,
    required this.earliest,
    required this.circleId,
  });

  final MedicationOccurrencesState state;
  final DateTime earliest;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MedicationOccurrencesCubit>();
    final DateTime now = PatientClockScope.of(context).now();
    return FilteredHistory<DoseOccurrence>(
      title: context.tr('medications.dose_history'),
      items: <DoseOccurrence>[
        for (final DoseOccurrence dose in state.occurrences.reversed)
          if (dose.isHistoryAt(now)) dose,
      ],
      dayOf: (item) => item.scheduledOn,
      byOf: (item) =>
          (item.record?.recordedByAccountId, item.record?.recordedByName),
      empty: InsetText(doseHistoryEmptyText(context, earliest)),
      builder: (shown) =>
          DoseHistoryDays(occurrences: shown, circleId: circleId),
      footer: cubit.canLoadEarlier(earliest)
          ? Center(
              child: TextButton(
                onPressed:
                    state.status == MedicationOccurrencesStatus.loadingMore
                    ? null
                    : () => cubit.loadEarlier(earliest),
                child: Text(context.tr('medications.load_earlier')),
              ),
            )
          : null,
    );
  }
}
