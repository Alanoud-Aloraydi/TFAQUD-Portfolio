import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the medication history section UI.
class MedicationHistorySection extends StatelessWidget {
  const MedicationHistorySection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) => ContentSwitcher(
        // Only loading, error and content fade; saving a change does not.
        stateKey: switch (state.status) {
          MedicationsStatus.initial || MedicationsStatus.loading => 'loading',
          MedicationsStatus.failure => 'failure',
          _ => 'content',
        },
        child: _content(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, MedicationsState state) {
    if (state.status == MedicationsStatus.initial ||
        state.status == MedicationsStatus.loading) {
      return const PlansSkeleton(filter: true);
    }
    if (state.status == MedicationsStatus.failure) {
      return RetryView(
        messageKey: state.messageKey!,
        onRetry: () => context.read<MedicationsCubit>().load(circleId),
      );
    }
    final today = PatientClockScope.of(context).today();
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
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        WhiteFilterMenu<MedicationRecordFilter>(
          options: {
            for (final filter in MedicationRecordFilter.values)
              filter: context.tr('medications.filter.${filter.name}'),
          },
          selected: state.recordFilter,
          onChanged: context.read<MedicationsCubit>().setRecordFilter,
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          EmptyStateNote.section(context.tr('medications.no_records'))
        else
          for (final plan in visible) ...[
            MedicationRecordCard(circleId: circleId, plan: plan),
            const SizedBox(height: AppItemCard.listGap),
          ],
      ],
    );
  }
}
