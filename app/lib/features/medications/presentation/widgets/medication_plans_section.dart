import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_list.dart';
import 'package:app/features/medications/presentation/widgets/plans_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الأدوية» on the plan tab: the list, with a fade between loading, a
/// failure and the medicines themselves.
class MedicationPlansSection extends StatelessWidget {
  const MedicationPlansSection({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
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
        child: MedicationPlansContent(
          circleId: circleId,
          canManage: canManage,
          header: header,
          state: state,
        ),
      ),
    );
  }
}

/// What «الأدوية» holds for one state of its cubit: the skeleton while it
/// loads, the retry view when it failed, or the medicines in use today.
class MedicationPlansContent extends StatelessWidget {
  const MedicationPlansContent({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
    required this.state,
  });

  final String circleId;
  final bool canManage;
  final Widget header;
  final MedicationsState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == MedicationsStatus.initial ||
        state.status == MedicationsStatus.loading) {
      return const PlansSkeleton();
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
    // No count line: the tab shows how many, and each card its status.
    return MedicationPlanList(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
      emptyText: CareVoice.tr(context, circleId, 'medications.no_current'),
      plans: current,
      circleId: circleId,
      canManage: canManage,
      // The cubit reads the list again by itself when the form saves.
      onAdd: () => context.push<bool>(CareItemRoutes.newMedication(circleId)),
    );
  }
}
