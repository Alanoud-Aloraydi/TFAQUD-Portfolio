import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_skeleton.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «سجل الجرعات» of one medicine, its extra doses among the others,
/// gathered in a box that folds away as «يحتاج انتباهك» does, with its
/// count. Two filters pick a day and who recorded; «أقدم» reads further
/// back.
class MedicationDoseHistory extends StatelessWidget {
  const MedicationDoseHistory({
    super.key,
    required this.earliest,
    required this.circleId,
    required this.medicine,
  });

  /// The medicine's first day: after today, the history says it starts.
  final DateTime earliest;

  final String circleId;
  final MedicationVersion medicine;

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
          _ => DoseHistoryView(
            state: state,
            earliest: earliest,
            circleId: circleId,
            medicine: medicine,
          ),
        },
      );
}
