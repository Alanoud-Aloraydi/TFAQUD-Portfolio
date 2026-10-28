import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TodayMedicationSection extends StatelessWidget {
  const TodayMedicationSection({super.key});

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
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.occurrences.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: AppSpacing.md)
              : const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) return _Header(count: state.occurrences.length);
            return DoseOccurrenceCard(occurrence: state.occurrences[index - 1]);
          },
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

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final date = formatMedicationDate(context, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('medications.today'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(date, style: Theme.of(context).textTheme.bodySmall),
          if (count == 0) ...[
            const SizedBox(height: AppSpacing.xxl),
            Center(child: Text(context.tr('medications.no_doses_today'))),
          ],
        ],
      ),
    );
  }
}
