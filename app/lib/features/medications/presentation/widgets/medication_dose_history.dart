import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_days.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «سجل الجرعات» of one medicine, gathered in a box that folds away as
/// «يحتاج انتباهك» does, with its count. Two filters pick a day and who
/// recorded; «أقدم» reads further back.
class MedicationDoseHistory extends StatelessWidget {
  const MedicationDoseHistory({
    super.key,
    required this.earliest,
    required this.circleId,
  });

  /// The medicine's first day: after today, the history says it starts.
  final DateTime earliest;

  final String circleId;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MedicationOccurrencesCubit, MedicationOccurrencesState>(
        // Only a failed «أقدم»: the answers to a dose show their own errors.
        listenWhen: (previous, current) =>
            current.messageKey != null &&
            previous.status == MedicationOccurrencesStatus.loadingMore,
        listener: (context, state) =>
            AppToast.show(context, state.messageKey!, kind: ToastKind.error),
        builder: (context, state) => switch (state.status) {
          MedicationOccurrencesStatus.loading => const DoseHistorySkeleton(),
          MedicationOccurrencesStatus.failure => RetryView(
            messageKey: state.messageKey!,
            onRetry: context.read<MedicationOccurrencesCubit>().reload,
          ),
          _ => _history(context, state),
        },
      );

  Widget _history(BuildContext context, MedicationOccurrencesState state) {
    final cubit = context.read<MedicationOccurrencesCubit>();
    return FilteredHistory<DoseOccurrence>(
      title: context.tr('medications.dose_history'),
      items: state.occurrences.reversed.toList(),
      dayOf: (item) => item.scheduledOn,
      byOf: (item) =>
          (item.record?.recordedByAccountId, item.record?.recordedByName),
      empty: InsetText(_emptyText(context)),
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

  /// Not started yet, or no dose was due in the days read.
  String _emptyText(BuildContext context) =>
      earliest.isAfter(PatientClockScope.of(context).today())
      ? context.tr(
          'medications.dose_history_not_started',
          args: <String>[formatMedicationDate(context, earliest)],
        )
      : context.tr('medications.no_dose_history');
}
