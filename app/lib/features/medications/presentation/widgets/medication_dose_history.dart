import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationDoseHistory extends StatelessWidget {
  const MedicationDoseHistory({super.key, required this.earliest});

  final DateTime earliest;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicationOccurrencesCubit, MedicationOccurrencesState>(
      listener: _showError,
      builder: (context, state) {
        if (state.status == MedicationOccurrencesStatus.loading) {
          return const LoadingWidget();
        }
        if (state.status == MedicationOccurrencesStatus.failure) {
          return MedicationFailureView(
            messageKey: state.messageKey!,
            onRetry: context.read<MedicationOccurrencesCubit>().reload,
          );
        }
        final items = state.occurrences.reversed.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('medications.dose_history'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            if (items.isEmpty)
              Text(context.tr('medications.no_dose_history'))
            else
              for (final item in items) ...[
                DoseOccurrenceCard(occurrence: item, showDate: true),
                const SizedBox(height: AppSpacing.md),
              ],
            if (context.read<MedicationOccurrencesCubit>().canLoadEarlier(
              earliest,
            ))
              Center(
                child: TextButton(
                  onPressed:
                      state.status == MedicationOccurrencesStatus.loadingMore
                      ? null
                      : () => context
                            .read<MedicationOccurrencesCubit>()
                            .loadEarlier(earliest),
                  child: Text(context.tr('medications.load_earlier')),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showError(BuildContext context, MedicationOccurrencesState state) {
    if (state.messageKey == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(state.messageKey!))));
  }
}
