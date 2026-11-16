import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/medication_record_filter.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_card.dart';
import 'package:app/features/medications/presentation/widgets/plans_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «السجل»'s medicines: the plans of [circleId], filtered by the choice
/// this section keeps for itself — the filter picks among plans already
/// loaded, so it is the page's state, not the cubit's.
class MedicationHistorySection extends StatefulWidget {
  const MedicationHistorySection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
  final Widget header;

  @override
  State<MedicationHistorySection> createState() =>
      _MedicationHistorySectionState();
}

class _MedicationHistorySectionState extends State<MedicationHistorySection> {
  MedicationRecordFilter _filter = MedicationRecordFilter.all;

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
        onRetry: () => context.read<MedicationsCubit>().load(widget.circleId),
      );
    }
    final DateTime today = PatientClockScope.of(context).today();
    final List<MedicationPlan> visible = state.plans
        .where((plan) => _filter.keeps(plan, today))
        .toList();
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        widget.header,
        const SizedBox(height: AppSpacing.md),
        WhiteFilterMenu<MedicationRecordFilter>(
          options: <MedicationRecordFilter, String>{
            for (final MedicationRecordFilter value
                in MedicationRecordFilter.values)
              value: context.tr(value.labelKey),
          },
          selected: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          EmptyStateNote.section(context.tr('medications.no_records'))
        else
          for (final plan in visible) ...[
            MedicationRecordCard(circleId: widget.circleId, plan: plan),
            const SizedBox(height: AppItemCard.listGap),
          ],
      ],
    );
  }
}
