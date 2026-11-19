import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/medication_record_filter.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_filter_menu.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_list.dart';
import 'package:app/features/medications/presentation/widgets/plans_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What «السجل» holds for one state of the medicines cubit: the skeleton,
/// the retry view, or the filter over the medicines it keeps.
class MedicationHistoryContent extends StatelessWidget {
  const MedicationHistoryContent({
    super.key,
    required this.circleId,
    required this.header,
    required this.canManage,
    required this.state,
    required this.filter,
    required this.onFilterChanged,
  });

  final String circleId;
  final Widget header;
  final bool canManage;
  final MedicationsState state;
  final MedicationRecordFilter filter;
  final ValueChanged<MedicationRecordFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
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
    final DateTime today = PatientClockScope.of(context).today();
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        MedicationRecordFilterMenu(filter: filter, onChanged: onFilterChanged),
        const SizedBox(height: AppSpacing.md),
        ...medicationRecordList(
          context,
          circleId: circleId,
          plans: state.plans
              .where((plan) => filter.keeps(plan, today))
              .toList(),
          // Only a circle with no medicine at all, as «الخطة» does.
          canAdd: canManage && state.plans.isEmpty,
        ),
      ],
    );
  }
}
