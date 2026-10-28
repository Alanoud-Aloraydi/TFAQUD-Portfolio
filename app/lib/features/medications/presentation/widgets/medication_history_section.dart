import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_list.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationHistorySection extends StatelessWidget {
  const MedicationHistorySection({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          return const LoadingWidget();
        }
        if (state.status == MedicationsStatus.failure) {
          return MedicationFailureView(
            messageKey: state.messageKey!,
            onRetry: () => context.read<MedicationsCubit>().load(circleId),
          );
        }
        final today = DateUtils.dateOnly(DateTime.now());
        final current = state.plans
            .where((plan) => !plan.isPreviousOn(today))
            .toList();
        final previous = state.plans
            .where((plan) => plan.isPreviousOn(today))
            .toList();
        final visible = switch (state.recordFilter) {
          MedicationRecordFilter.all => state.plans,
          MedicationRecordFilter.current => current,
          MedicationRecordFilter.previous => previous,
        };
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CupertinoSlidingSegmentedControl<MedicationRecordFilter>(
              groupValue: state.recordFilter,
              children: {
                for (final filter in MedicationRecordFilter.values)
                  filter: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      context.tr('medications.filter.${filter.name}'),
                    ),
                  ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  context.read<MedicationsCubit>().setRecordFilter(value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            MedicationPlanList(
              title: context.tr(
                'medications.filter.${state.recordFilter.name}',
              ),
              emptyText: context.tr('medications.no_records'),
              plans: visible,
              circleId: circleId,
              shrinkWrap: true,
            ),
          ],
        );
      },
    );
  }
}
