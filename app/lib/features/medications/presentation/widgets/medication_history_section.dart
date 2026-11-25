import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_list.dart';
import 'package:app/features/medications/presentation/widgets/plans_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «السجل»'s medicines: the plans of [circleId] under a filter, as the
/// readings and the visits have — «الكل», «الحالية», «السابقة». It opens
/// on «الكل». The filter picks among plans already loaded, so it is this
/// page's state, not the cubit's.
class MedicationHistorySection extends StatefulWidget {
  const MedicationHistorySection({
    super.key,
    required this.circleId,
    required this.header,
    required this.canManage,
  });

  final String circleId;
  final Widget header;

  /// Whether the empty record offers «جدولة دواء».
  final bool canManage;

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
        child: MedicationHistoryContent(
          circleId: widget.circleId,
          header: widget.header,
          canManage: widget.canManage,
          state: state,
          filter: _filter,
          onFilterChanged: (value) => setState(() => _filter = value),
        ),
      ),
    );
  }
}

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

/// Which medicines «السجل» shows: all of them, or one state of a plan.
class MedicationRecordFilterMenu extends StatelessWidget {
  const MedicationRecordFilterMenu({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final MedicationRecordFilter filter;
  final ValueChanged<MedicationRecordFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return WhiteFilterMenu<MedicationRecordFilter>(
      options: <MedicationRecordFilter, String>{
        for (final MedicationRecordFilter value
            in MedicationRecordFilter.values)
          value: context.tr(value.labelKey),
      },
      selected: filter,
      onChanged: onChanged,
    );
  }
}

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
