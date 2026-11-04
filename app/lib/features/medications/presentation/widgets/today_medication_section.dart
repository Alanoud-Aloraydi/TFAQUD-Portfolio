import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the today medication section UI.
class TodayMedicationSection extends StatelessWidget {
  const TodayMedicationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicationOccurrencesCubit, MedicationOccurrencesState>(
      listener: _showError,
      builder: (context, state) => ContentSwitcher(
        // Only loading, error and content fade; recording a dose does not.
        stateKey: switch (state.status) {
          MedicationOccurrencesStatus.loading => 'loading',
          MedicationOccurrencesStatus.failure => 'failure',
          _ => 'content',
        },
        child: _content(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, MedicationOccurrencesState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.tr('medications.today'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == MedicationOccurrencesStatus.loading) ...<Widget>[
          const DoseRowSkeleton(withButtons: true),
          const Divider(height: AppSizes.divider),
          const DoseRowSkeleton(),
        ] else if (state.status == MedicationOccurrencesStatus.failure)
          MedicationFailureView(
            messageKey: state.messageKey!,
            onRetry: context.read<MedicationOccurrencesCubit>().reload,
          )
        else if (state.occurrences.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: Text(context.tr('medications.no_doses_today')),
            ),
          )
        else
          for (var index = 0; index < state.occurrences.length; index++) ...[
            if (index > 0) const Divider(height: AppSizes.divider),
            DoseOccurrenceCard(occurrence: state.occurrences[index]),
          ],
      ],
    );
  }

  void _showError(BuildContext context, MedicationOccurrencesState state) {
    if (state.messageKey == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(state.messageKey!))));
  }
}
